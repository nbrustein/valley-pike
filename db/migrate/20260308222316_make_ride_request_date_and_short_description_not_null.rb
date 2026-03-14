class MakeRideRequestDateAndShortDescriptionNotNull < ActiveRecord::Migration[8.1]
  def up
    change_column_null :ride_requests, :date, false
    change_column_null :ride_requests, :short_description, false
  end

  def down
    change_column_null :ride_requests, :date, true
    change_column_null :ride_requests, :short_description, true
  end
end
