class UserViewPolicy < PolicyBase
  include Memery

  memoize def index?
    roles_granting_org_admin_permissions&.any?
  end

  memoize def scope
    return User.where("FALSE") unless index?

    query = User.joins(:user_roles).where(
      user_roles: {
        role: viewable_roles,
        organization_id: organization_ids_with_org_admin_permissions
      }
    )
    query
  end

  private

  memoize def viewable_roles
    return UserRole::ROLES if current_user&.has_role_permissions?(UserRole::VANITA_ADMIN)
    return [ UserRole::RIDE_REQUESTER ] if current_user&.has_role_permissions?(UserRole::ORG_ADMIN)
    []
  end

  memoize def roles_granting_org_admin_permissions
    current_user&.roles_with_permissions(UserRole::ORG_ADMIN) || []
  end

  def organization_ids_with_org_admin_permissions
    if roles_granting_org_admin_permissions.any? {|role| role.organization_id.nil? }
      return Organization.ids
    end

    roles_granting_org_admin_permissions.filter_map(&:organization_id).compact.uniq
  end
end
