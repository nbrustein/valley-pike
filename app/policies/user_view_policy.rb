class UserViewPolicy < ApplicationPolicy
  module Helpers
    include Memery

    memoize def viewable_roles
      return UserRole::ROLES if user&.has_role_permissions?(UserRole::VANITA_ADMIN)
      return [ UserRole::RIDE_REQUESTER ] if user&.has_role_permissions?(UserRole::ORG_ADMIN)
      []
    end

    memoize def roles_granting_org_admin_permissions
      user&.roles_with_permissions(UserRole::ORG_ADMIN) || []
    end

    def organization_ids_with_org_admin_permissions
      if roles_granting_org_admin_permissions.any? {|role| role.organization_id.nil? }
        return Organization.ids
      end

      roles_granting_org_admin_permissions.filter_map(&:organization_id).compact.uniq
    end
  end

  include Helpers

  memoize def index?
    user&.has_role_permissions?(UserRole::ORG_ADMIN) || false
  end

  class Scope < Scope
    include Helpers

    def resolve
      return User.where("FALSE") unless policy.index?

      User.joins(:user_roles).where(
        user_roles: {
          role: viewable_roles,
          organization_id: organization_ids_with_org_admin_permissions
        }
      )
    end

    private

    def policy
      @policy ||= UserViewPolicy.new(user, nil)
    end
  end
end
