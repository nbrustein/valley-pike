module IsUserPolicy
  include Memery

  memoize def permits_users_with_roles
    return UserRole::ROLES.to_a if user&.has_role_permissions?(UserRole::VANITA_ADMIN)
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
