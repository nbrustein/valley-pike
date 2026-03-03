module OrganizationsHelper
  include Memery

  memoize def show_organizations_index_link?
    OrganizationViewPolicy::Scope.new(current_user, nil).resolve.exists?
  end

  memoize def organization_create_allowed?
    OrganizationMutatePolicy.new(current_user, nil).new?
  end

  def organization_edit_allowed?(organization)
    OrganizationMutatePolicy.new(current_user, organization).edit?
  end
end
