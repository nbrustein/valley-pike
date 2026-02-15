class UserPolicy < ApplicationPolicy
  def index?
    user&.has_role_permissions?(UserRole::ORG_ADMIN) || false
  end

  class Scope < Scope
    def resolve
      return scope.none unless user&.has_role_permissions?(UserRole::ORG_ADMIN)

      users = base_scope
      return users if can_view_all_users?

      # People who cannot view all users (i.e. org admins) can only view
      # the other org admins in their organization.
      users.joins(:user_roles).where(
        user_roles: {
          role: UserRole::ORG_ADMIN,
          organization_id: permitted_org_ids
        }
      )
    end

    private

    def base_scope
      scope.joins(:human)
        .includes(:human, user_roles: :organization)
        .order("humans.sortable_name ASC")
        .distinct
    end

    def can_view_all_users?
      roles_granting_org_admin_permissions.any? {|role| role.organization_id.nil? }
    end

    def permitted_org_ids
      roles_granting_org_admin_permissions.filter_map(&:organization_id).uniq
    end

    def roles_granting_org_admin_permissions
      user.roles_with_permissions(UserRole::ORG_ADMIN)
    end
  end
end
