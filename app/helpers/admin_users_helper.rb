module AdminUsersHelper
  include Memery

  memoize def show_users_index_link?
    AdminUserViewPolicy::Scope.new(current_user, nil).resolve.exists?
  end

  memoize def user_create_allowed?
    AdminUserMutatePolicy.new(current_user, nil).new?
  end

  def user_edit_allowed?(target_user)
    AdminUserMutatePolicy.new(current_user, target_user).edit?
  end

  def user_display_name(user)
    suffix = user.disabled? ? " [DISABLED]" : ""
    "#{user.human.full_name}#{suffix}"
  end
end
