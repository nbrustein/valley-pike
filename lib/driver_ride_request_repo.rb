class DriverRideRequestRepo
  def initialize(current_user:)
    @current_user = current_user
  end

  def list
    scope = DriverRideRequestPolicy::Scope.new(@current_user, RideRequest).resolve
    sorted(scope)
  end

  private

  def sorted(scope)
    today = Date.current
    driver_id = @current_user.id

    scope
      .includes(:organization, :destination_address, :driver_assignments)
      .order(
        Arel.sql(sort_sql(today, driver_id))
      )
  end

  # Sort order:
  # 1. Future (today or later) before past
  # 2. Assigned to this driver before unassigned
  # 3. Needs drivers (has_enough_drivers=false) before fully staffed
  # 4. Date ascending for future rides, descending for past rides
  def sort_sql(today, driver_id)
    ActiveRecord::Base.sanitize_sql_array([
      <<~SQL.squish,
        CASE WHEN ride_requests.date >= ? THEN 0 ELSE 1 END ASC,
        CASE WHEN ride_requests.id IN (SELECT ride_request_id FROM driver_assignments WHERE driver_id = ?) THEN 0 ELSE 1 END ASC,
        CASE WHEN ride_requests.has_enough_drivers = FALSE THEN 0 ELSE 1 END ASC,
        CASE WHEN ride_requests.date >= ? THEN ride_requests.date END ASC,
        CASE WHEN ride_requests.date < ? THEN ride_requests.date END DESC
      SQL
      today, driver_id, today, today
    ])
  end
end
