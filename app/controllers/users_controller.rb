class UsersController < ApplicationController
  def index
    return head :not_found unless current_user&.has_role_permissions?(UserRole::ORG_ADMIN)

    @users = visible_users
  end

  private

  def visible_users
    scoped_users = User.joins(:human)
      .includes(:human, user_roles: :organization)
      .order("humans.sortable_name ASC")
      .distinct

    return scoped_users if can_view_all_users?

    scoped_users.joins(:user_roles).where(
      user_roles: {
        role: UserRole::ORG_ADMIN,
        organization_id: permitted_org_ids
      }
    )
  end

  def can_view_all_users?
    roles_granting_org_admin_permissions.any? {|user_role| user_role.organization_id.nil? }
  end

  def permitted_org_ids
    roles_granting_org_admin_permissions.filter_map(&:organization_id).uniq
  end

  def roles_granting_org_admin_permissions
    current_user.roles_with_permissions(UserRole::ORG_ADMIN)
  end
end
