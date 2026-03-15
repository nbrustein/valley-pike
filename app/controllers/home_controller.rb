class HomeController < ApplicationController
  include Memery

  def index
    if driver?
      render_driver_home
    elsif can_view_admin_ride_requests?
      redirect_to admin_ride_requests_path
    else
      render_welcome
    end
  end

  private

  def driver?
    current_user&.has_role_permissions?(UserRole::DRIVER)
  end

  memoize def can_view_admin_ride_requests?
    return false unless current_user

    AdminRideRequestViewPolicy.new(current_user, nil).index?
  end

  def render_driver_home
    ride_requests = DriverRideRequestRepo.new(current_user:).list
    @component = DriverRideRequestsIndexComponent.new(ride_requests:, current_user:)
  end

  def render_welcome
    @component = WelcomeComponent.new(identity: current_identity)
  end
end
