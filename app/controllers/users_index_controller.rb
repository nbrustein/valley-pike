class UsersIndexController < ApplicationController
  include Memery

  def index
    authorize(nil, :index?, policy_class: UserViewPolicy)
    @users = policy_scope(User, policy_scope_class: UserViewPolicy::Scope)
      .joins(:human)
      .includes(:human, user_roles: :organization)
      .order(humans: {sortable_name: :asc})
      .distinct
  end
end
