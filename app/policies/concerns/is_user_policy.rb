module IsUserPolicy
  include Memery

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
