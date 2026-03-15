module AdminOrganizationsHelper
  include Memery

  memoize def show_organizations_index_link?
    AdminOrganizationViewPolicy::Scope.new(current_user, nil).resolve.exists?
  end

  memoize def organization_create_allowed?
    AdminOrganizationMutatePolicy.new(current_user, nil).new?
  end

  def organization_edit_allowed?(organization)
    AdminOrganizationMutatePolicy.new(current_user, organization).edit?
  end
end
