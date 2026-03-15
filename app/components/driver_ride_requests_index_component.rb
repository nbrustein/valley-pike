class DriverRideRequestsIndexComponent < ViewComponent::Base
  def initialize(ride_requests:)
    @ride_requests = ride_requests
  end
end
