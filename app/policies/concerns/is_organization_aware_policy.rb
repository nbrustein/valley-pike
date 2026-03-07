module IsOrganizationAwarePolicy
  include Memery

  # Including policy must define: roles_granting_permissions
  # e.g. memoize def roles_granting_permissions
  #        user&.roles_with_permissions(UserRole::RIDE_REQUESTER) || []
  #      end

  memoize def all_organizations_permitted?
    roles_granting_permissions.any? {|role| role.organization_id.nil? }
  end

  memoize def permitted_organization_ids
    if all_organizations_permitted?
      return Organization.ids + [ nil ]
    end

    roles_granting_permissions.filter_map(&:organization_id).compact.uniq
  end
end
