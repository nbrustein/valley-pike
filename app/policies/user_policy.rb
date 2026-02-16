class UserPolicy < ApplicationPolicy
  def index?
    user&.has_role_permissions?(UserRole::ORG_ADMIN) || false
  end

  def can_manage_all_users?
    user.has_role_permissions?(UserRole::VANITA_ADMIN)
  end

  def has_org_admin_permissions_for_all_organizations?
    return false if user.nil?

    roles_granting_org_admin_permissions.any? {|role| role.organization_id.nil? }
  end

  class Scope < Scope
    def resolve
      return scope.none unless user&.has_role_permissions?(UserRole::ORG_ADMIN)

      users = base_scope

      return users if policy.send(:can_manage_all_users?)
      return users.joins(:user_roles).where(
        user_roles: {
          role: UserRole::RIDE_REQUESTER,
          organization_id: organization_ids_with_org_admin_permissions
        }
      )

      raise NotImplementedError, "Hit an unexpected situation in UserPolicy::Scope#resolve"
    end

    private

    def policy
      UserPolicy.new(user, nil)
    end

    def base_scope
      scope.joins(:human)
        .includes(:human, user_roles: :organization)
        .order("humans.sortable_name ASC")
        .distinct
    end

    def organization_ids_with_org_admin_permissions
      user.roles_with_permissions(UserRole::ORG_ADMIN)
        .filter_map(&:organization_id)
        .uniq
    end
  end

  private

  def roles_granting_org_admin_permissions
    user.roles_with_permissions(UserRole::ORG_ADMIN)
  end

  def has_org_admin_permissions_only_for_own_organization?
    return false if user.nil?

    roles_granting_org_admin_permissions.any? {|role| role.organization_id.present? }
  end
end
