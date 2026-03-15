class HomeController < ApplicationController
  include Memery

  def index
    if driver?
      render_driver_home
    elsif can_view_admin_ride_requests?
      redirect_to admin_ride_requests_path
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
    scope = DriverRideRequestPolicy::Scope.new(current_user, RideRequest).resolve
    @ride_requests = sorted_ride_requests(scope)
  end

  def sorted_ride_requests(scope)
    today = Date.current
    driver_id = current_user.id

    scope
      .includes(:organization, :destination_address, :driver_assignments)
      .order(
        Arel.sql(sanitize_sort_sql(today, driver_id))
      )
  end

  def sanitize_sort_sql(today, driver_id)
    ActiveRecord::Base.sanitize_sql_array([
      <<~SQL.squish,
        CASE WHEN date >= ? THEN 0 ELSE 1 END ASC,
        CASE WHEN id IN (SELECT ride_request_id FROM driver_assignments WHERE driver_id = ?) THEN 0 ELSE 1 END ASC,
        CASE WHEN has_enough_drivers = FALSE THEN 0 ELSE 1 END ASC,
        CASE WHEN date >= ? THEN date END ASC,
        CASE WHEN date < ? THEN date END DESC
      SQL
      today, driver_id, today, today
    ])
  end
end
