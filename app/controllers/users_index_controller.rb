class UsersIndexController < ApplicationController
  include Memery
  before_action :authorize_user_view

  def index
    authorize User, :index?
    @users = policy_scope(User)
  end

  private

  def authorize_user_view
    raise PolicyBase::NotAuthorizedError unless UserViewPolicy.new(current_user).index?
  end
end
