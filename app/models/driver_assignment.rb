class DriverAssignment < ApplicationRecord
  belongs_to :ride_request
  belongs_to :driver, class_name: "User"

  validates :driver_id, uniqueness: {scope: :ride_request_id}
end
