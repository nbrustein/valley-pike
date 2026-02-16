class UserPolicy < ApplicationPolicy
  def index?
    user&.has_role_permissions?(UserRole::ORG_ADMIN) || false
  end

  def create?
    if record == User
      return user.has_role_permissions?(UserRole::ORG_ADMIN)
    end
    return false if user.nil? || record.nil?
    return false unless record.user_roles.size == 1

    user_role = record.user_roles.first
    return false unless user_role.role == UserRole::RIDE_REQUESTER

    organization_id = user_role.organization_id
    return false if organization_id.blank?

    permitted_org_ids_for_role_management.include?(organization_id)
  end

  def can_manage_all_users?
    user&.has_role_permissions?(UserRole::VANITA_ADMIN) || false
  end

  def has_org_admin_permissions_for_all_organizations?
    return false if user.nil?

    roles_granting_org_admin_permissions.any? {|role| role.organization_id.nil? }
  end

  def permitted_org_ids_for_role_management
    return Organization.ids if can_manage_all_users?

    organization_ids_with_org_admin_permissions
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
    return [] if user.nil?

    user.roles_with_permissions(UserRole::ORG_ADMIN)
  end

  def organization_ids_with_org_admin_permissions
    roles_granting_org_admin_permissions
      .filter_map(&:organization_id)
      .uniq
  end

  def has_org_admin_permissions?
    roles_granting_org_admin_permissions.any?
  end
end
