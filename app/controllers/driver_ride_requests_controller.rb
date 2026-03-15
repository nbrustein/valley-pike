class DriverRideRequestsController < ApplicationController
  include Memery

  def show
    return render_not_found unless target_ride_request.present?

    authorize(target_ride_request, :show?, policy_class: DriverRideRequestPolicy)
    @component = DriverRideRequestShowComponent.new(ride_request: target_ride_request, current_user:)
  end

  def accept
    return render_not_found unless target_ride_request.present?

    authorize(target_ride_request, :accept?, policy_class: DriverRideRequestPolicy)

    result = UnitsOfWork::AcceptRideRequest.execute(
      executor_id: current_user.id,
      params: {ride_request_id: target_ride_request.id}
    )

    if result.success?
      redirect_to driver_ride_request_path(id: target_ride_request.id),
notice: "You are assigned as the driver for this ride."
    else
      redirect_to driver_ride_request_path(id: target_ride_request.id),
        alert: result.errors.full_messages.join(", ")
    end
  end

  private

  memoize def target_ride_request
    RideRequest.find_by(id: params[:id])
  end
end
