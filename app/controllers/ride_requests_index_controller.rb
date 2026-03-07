class RideRequestsIndexController < ApplicationController
  include Memery

  def index
    authorize(nil, :index?, policy_class: RideRequestViewPolicy)
    @ride_requests = policy_scope(RideRequest, policy_scope_class: RideRequestViewPolicy::Scope)
      .includes(:organization)
      .order(date: :desc)
  end
end
