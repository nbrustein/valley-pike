class UserMutatePolicy < ApplicationPolicy
  include IsUserPolicy

  alias_method :uow, :record
  
  def new?
    user&.has_role_permissions?(UserRole::ORG_ADMIN) || false
  end

  def create?
    return false unless new?
    return false if (uow.user_roles.pluck(:role).uniq - permits_users_with_roles).any?
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
end
