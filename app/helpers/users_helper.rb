module UsersHelper
  include Memery

  memoize def show_users_index_link?
    UserPolicy::Scope.new(current_user, User).resolve.exists?
  end

  memoize def users_index_label
    return "Users" if permitted_org_abbreviations.count > 1
    return nil if permitted_org_abbreviations.empty?
    abbreviation = permitted_org_abbreviations.first

    "#{abbreviation} Users"
  end

  private

  memoize def view_users_policy
    UserPolicy.new(current_user, nil)
  end

  memoize def permitted_org_abbreviations
    permitted_organizations.map(&:abbreviation)
  end

  memoize def permitted_organizations
    view_users_policy.send(:roles_granting_org_admin_permissions)
      .filter_map(&:organization)
      .uniq
  end
end
