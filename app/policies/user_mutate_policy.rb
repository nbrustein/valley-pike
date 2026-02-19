class UserMutatePolicy < ApplicationPolicy
  include IsUserPolicy

  alias_method :uow, :record

  def new?
    user&.has_role_permissions?(UserRole::ORG_ADMIN) || false
  end

  def create?
    return false unless new?
    return false if uow.user_roles.empty? # can't create a user without any roles
    return false if (uow.user_roles.pluck(:role).uniq - manageable_roles).any?
    return false if (uow.user_roles.pluck(:organization_id).uniq - organization_ids_with_org_admin_permissions).any?

    true
  end

  class OrganizationScope < Scope
    include IsUserPolicy

    def resolve
      Organization.where(id: organization_ids_with_org_admin_permissions)
    end

    private

    memoize def policy
      UserMutatePolicy.new(user, nil)
    end
  end

  def manageable_roles
    return UserRole::ROLES if user&.has_role_permissions?(UserRole::DEVELOPER)
    return [ UserRole::ORG_ADMIN, UserRole::RIDE_REQUESTER, UserRole::DRIVER ] if user&.has_role_permissions?(UserRole::VANITA_ADMIN)
    return [ UserRole::RIDE_REQUESTER ] if user&.has_role_permissions?(UserRole::ORG_ADMIN)
    []
  end
end
