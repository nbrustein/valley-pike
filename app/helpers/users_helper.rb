module UsersHelper
  include Memery

  memoize def show_users_index_link?
    UserViewPolicy::Scope.new(current_user, nil).resolve.exists?
  end

  memoize def users_index_label
    return "Users" if permitted_org_abbreviations.count > 1
    return nil if permitted_org_abbreviations.empty?
    abbreviation = permitted_org_abbreviations.first

    "#{abbreviation} Users"
  end

  memoize def user_create_allowed?
    UserMutatePolicy.new(current_user, nil).new?
  end

  private

  memoize def view_users_policy
    UserViewPolicy.new(current_user, nil)
  end

  memoize def permitted_org_abbreviations
    permitted_organizations.map(&:abbreviation)
  end

  memoize def permitted_organizations
    Organization.where(id: view_users_policy.send(:organization_ids_with_org_admin_permissions))
  end
end
