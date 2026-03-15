class AdminRideRequestMutatePolicy < ApplicationPolicy
  include IsOrganizationAwarePolicy

  memoize def new?
    user&.has_role_permissions?(UserRole::RIDE_REQUESTER) || false
  end

  def create?
    return false unless new?
    return false unless uow

    can_create?(uow.organization_id)
  end

  def edit?
    return false unless new?
    return false unless target_ride_request

    can_create?(target_ride_request.organization_id)
  end

  # If the current user is allowed to edit the target record, and they would be allowed
  # to create a record with the current params, then they are allowed to update the record.
  def update?
    edit? && create?
  end

  def can_create?(ride_request_organization_id)
    permitted_organization_ids.include?(ride_request_organization_id)
  end

  def uow
    record.is_a?(UnitOfWork) ? record : nil
  end

  def target_ride_request
    record.is_a?(RideRequest) ? record : nil
  end

  memoize def roles_granting_permissions
    user&.roles_with_permissions(UserRole::RIDE_REQUESTER) || []
  end
end
