class UserPolicy < ApplicationPolicy
  def index?
    user&.has_role_permissions?(UserRole::ORG_ADMIN) || false
  end

  def restricted_to_viewing_ride_requesters_for_own_organization?
    return false unless user&.has_role_permissions?(UserRole::ORG_ADMIN)

    !can_view_all_users?
  end

  def can_view_all_users?
    return false if user.nil?

    roles_granting_org_admin_permissions.any? {|role| role.organization_id.nil? }
  end

  class Scope < Scope
    def resolve
      return scope.none unless user&.has_role_permissions?(UserRole::ORG_ADMIN)

      users = base_scope
      return users if UserPolicy.new(user, nil).send(:can_view_all_users?)
      if restricted_to_viewing_ride_requesters_for_own_organization?
        return users.joins(:user_roles).where(
          user_roles: {
            role: UserRole::RIDE_REQUESTER,
            organization_id: permitted_org_ids
          }
        )
      end

      raise NotImplementedError, "Hit an unexpected situation in UserPolicy::Scope#resolve"
    end

    private

    def base_scope
      scope.joins(:human)
        .includes(:human, user_roles: :organization)
        .order("humans.sortable_name ASC")
        .distinct
    end

    def restricted_to_viewing_ride_requesters_for_own_organization?
      UserPolicy.new(user, nil)
        .restricted_to_viewing_ride_requesters_for_own_organization?
    end

    def permitted_org_ids
      user.roles_with_permissions(UserRole::ORG_ADMIN)
        .filter_map(&:organization_id)
        .uniq
    end
  end

  private

  def roles_granting_org_admin_permissions
    user.roles_with_permissions(UserRole::ORG_ADMIN)
  end
end
