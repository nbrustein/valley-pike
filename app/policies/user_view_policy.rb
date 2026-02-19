class UserViewPolicy < ApplicationPolicy
  include IsUserPolicy

  memoize def index?
    user&.has_role_permissions?(UserRole::ORG_ADMIN) ||
      user&.has_role_permissions?(UserRole::VANITA_VIEWER) ||
      false
  end

  class Scope < Scope
    include IsUserPolicy

    def resolve
      return User.where("FALSE") unless policy.index?

      User.joins(:user_roles).where(
        user_roles: {
          role: viewable_roles,
          organization_id: organization_ids_with_org_admin_permissions,
        }
      )
    end

    private

    memoize def policy
      UserViewPolicy.new(user, nil)
    end

    memoize def viewable_roles
      return UserRole::ROLES if user&.has_role_permissions?(UserRole::VANITA_VIEWER)
      return [ UserRole::RIDE_REQUESTER ] if user&.has_role_permissions?(UserRole::ORG_ADMIN)
      []
    end
  end
end
