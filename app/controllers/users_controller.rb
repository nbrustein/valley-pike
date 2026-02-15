class UsersController < ApplicationController
  def index
    authorize User, :index?
    @users = policy_scope(User)
  end
end
