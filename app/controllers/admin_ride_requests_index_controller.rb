class AdminRideRequestsIndexController < ApplicationController
  include Memery

  def index
    authorize(nil, :index?, policy_class: AdminRideRequestViewPolicy)
    @ride_requests = policy_scope(RideRequest, policy_scope_class: AdminRideRequestViewPolicy::Scope)
      .includes(:organization)
      .order(date: :desc)
  end
end
