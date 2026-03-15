class RideRequestAssignmentValidator
  attr_reader :errors

  def initialize(ride_requests: [], driver_assignments: [], organizations: [],
    removed_user_roles: [], removed_driver_qualifications: [])
    @ride_requests = ride_requests
    @driver_assignments = driver_assignments
    @organizations = organizations
    @removed_user_roles = removed_user_roles
    @removed_driver_qualifications = removed_driver_qualifications
    @errors = ActiveModel::Errors.new(self)
  end

  def validate
    validate_no_draft_ride_requests_with_assignments
    validate_no_assignments_to_drafts
    validate_driver_role_not_removed_with_active_assignments
    validate_drivers_meet_required_qualifications
    errors.empty?
  end

  private

  def validate_no_draft_ride_requests_with_assignments
    @ride_requests.each do |ride_request|
      next unless ride_request.draft? && ride_request.draft_changed?
      next unless ride_request.driver_assignments.any?

      errors.add(:base, "Cannot change ride request to draft when drivers are assigned")
    end
  end

  def validate_no_assignments_to_drafts
    @driver_assignments.each do |assignment|
      next unless assignment.new_record?
      next unless assignment.ride_request&.draft?

      errors.add(:base, "Cannot assign a driver to a draft ride request")
    end
  end

  def validate_driver_role_not_removed_with_active_assignments
    @removed_user_roles.each do |user_role|
      next unless user_role.role == UserRole::DRIVER
      next unless active_assignments_for_user(user_role.user).any?

      errors.add(:base, "Cannot remove driver role while user has active ride assignments")
    end
  end

  def validate_drivers_meet_required_qualifications
    each_ride_request_to_check do |ride_request, required_qualifications|
      ride_request.drivers.each do |driver|
        driver_quals = effective_qualifications_for(driver)
        missing = required_qualifications - driver_quals
        next if missing.empty?

        errors.add(:base,
          "Driver #{driver.email} is missing required qualifications: #{missing.join(", ")}")
      end
    end
  end

  def each_ride_request_to_check
    @ride_requests.each do |ride_request|
      next unless ride_request.organization_id_changed?
      next if ride_request.completed? || ride_request.cancelled?

      new_org = Organization.find_by(id: ride_request.organization_id)
      next if new_org.nil?

      yield ride_request, new_org.required_qualifications
    end

    @organizations.each do |org|
      next unless org.required_qualifications_changed?

      driver_ride_requests_for_org(org).each do |ride_request|
        yield ride_request, org.required_qualifications
      end
    end

    users_with_removed_qualifications.each do |user_id, removed_quals|
      active_assignments_for_user_id(user_id).includes(ride_request: :organization).each do |assignment|
        yield assignment.ride_request, assignment.ride_request.organization.required_qualifications
      end
    end
  end

  def effective_qualifications_for(driver)
    removed = removed_qualifications_by_user_id[driver.id]
    if removed
      driver.driver_qualifications.pluck(:qualification) - removed
    else
      driver.driver_qualifications.pluck(:qualification)
    end
  end

  def users_with_removed_qualifications
    removed_qualifications_by_user_id
  end

  def removed_qualifications_by_user_id
    @removed_qualifications_by_user_id ||= @removed_driver_qualifications
      .group_by(&:user_id)
      .transform_values {|dqs| dqs.map(&:qualification) }
  end

  def active_assignments_for_user(user)
    active_assignments_for_user_id(user.id)
  end

  def active_assignments_for_user_id(user_id)
    DriverAssignment
      .joins(:ride_request)
      .where(driver_id: user_id)
      .where(ride_requests: {completed: false, cancelled: false})
  end

  def driver_ride_requests_for_org(org)
    RideRequest
      .joins(:driver_assignments)
      .where(organization: org, completed: false, cancelled: false)
      .distinct
  end
end
