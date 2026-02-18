class UserViewPolicy < ApplicationPolicy
  include IsUserPolicy

  memoize def index?
    user&.has_role_permissions?(UserRole::ORG_ADMIN) || false
  end

  class Scope < Scope
    include IsUserPolicy

    def resolve
      return User.where("FALSE") unless policy.index?

      User.joins(:user_roles).where(
        user_roles: {
          role: permits_users_with_roles,
          organization_id: organization_ids_with_org_admin_permissions,
        }
      )
    end

    private

    memoize def policy
      UserViewPolicy.new(user, nil)
    end
  end
end
