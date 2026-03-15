class DriverRideRequestPolicy < ApplicationPolicy
  def index?
    # Admins can view the ride request admin screen, but the they can only view
    # the driver screen if the also have the driver role.
    user&.has_role_permissions?(UserRole::DRIVER) || false
  end

  def show?
    index? && Scope.new(user, RideRequest).resolve.exists?(record.id)
  end

  def accept?
    show?
  end

  class Scope < Scope
    def resolve
      return RideRequest.where("FALSE") unless policy.index?

      assigned_rides.or(qualifying_future_rides)
    end

    private

    def assigned_rides
      # We use the where with the sub-select so that this can be combined with
      # qualifying_future_rides with `or`
      RideRequest
        .where(id: DriverAssignment.where(driver_id: user.id).select(:ride_request_id))
    end

    def qualifying_future_rides
      RideRequest
        .where(draft: false, cancelled: false, completed: false)
        .where("date >= ?", Date.current)
        .where(organization_id: qualifying_organization_ids)
    end

    memoize def qualifying_organization_ids
      user_qualifications = user.driver_qualifications.pluck(:qualification)
      Organization.all.select {|org|
        (org.required_qualifications - user_qualifications).empty?
      }.map(&:id)
    end

    memoize def policy
      DriverRideRequestPolicy.new(user, nil)
    end
  end
end
