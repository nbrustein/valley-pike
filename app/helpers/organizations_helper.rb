module OrganizationsHelper
  include Memery

  memoize def show_organizations_index_link?
    OrganizationViewPolicy::Scope.new(current_user, nil).resolve.exists?
  end

  memoize def organization_create_allowed?
    OrganizationMutatePolicy.new(current_user, nil).new?
  end
end
