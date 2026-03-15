class AdminUsersIndexController < ApplicationController
  include Memery

  def index
    authorize(nil, :index?, policy_class: AdminUserViewPolicy)
    @users = policy_scope(User, policy_scope_class: AdminUserViewPolicy::Scope)
      .joins(:human)
      .includes(:human, user_roles: :organization)
      .order(humans: {full_name: :asc})
      .distinct
  end
end
