module IsOrganizationAwarePolicy
  include Memery

  # Including policy must define: roles_granting_org_permissions
  # e.g. memoize def roles_granting_org_permissions
  #        user&.roles_with_permissions(UserRole::RIDE_REQUESTER) || []
  #      end

  def permitted_organization_ids
    if roles_granting_org_permissions.any? {|role| role.organization_id.nil? }
      return Organization.ids + [ nil ]
    end

    roles_granting_org_permissions.filter_map(&:organization_id).compact.uniq
  end
end
