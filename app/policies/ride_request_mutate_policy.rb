class RideRequestMutatePolicy < ApplicationPolicy
  include IsOrganizationAwarePolicy

  memoize def new?
    user&.has_role_permissions?(UserRole::RIDE_REQUESTER) || false
  end

  def create?
    return false unless new?
    return false unless uow

    permitted_organization_ids.include?(uow.organization_id)
  end

  def uow
    record.is_a?(UnitOfWork) ? record : nil
  end

  memoize def roles_granting_permissions
    user&.roles_with_permissions(UserRole::RIDE_REQUESTER) || []
  end
end
