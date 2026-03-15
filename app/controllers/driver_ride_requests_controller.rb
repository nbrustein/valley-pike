class DriverRideRequestsController < ApplicationController
  include Memery

  def show
    return render_not_found unless target_ride_request.present?

    authorize(target_ride_request, :show?, policy_class: DriverRideRequestPolicy)
    @ride_request = target_ride_request
  end

  private

  memoize def target_ride_request
    RideRequest.find_by(id: params[:id])
  end
end
