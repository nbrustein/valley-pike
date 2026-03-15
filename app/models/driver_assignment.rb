class DriverAssignment < ApplicationRecord
  belongs_to :ride_request
  belongs_to :driver, class_name: "User"

  validates :driver_id, uniqueness: {scope: :ride_request_id}
  validate :add_error_if_ride_request_changed, on: :update
  before_destroy :prevent_destroy

  private

  # This just seems to add unnecessary confusion, so prevent it
  def add_error_if_ride_request_changed
    if ride_request_id_changed?
      errors.add(:ride_request, "cannot be changed")
    end
  end

  # We may have to think about this at soem point, but avoid it for now.
  # If we do destroy or assignments or mark them as canceled, consider if
  # RideRequestAssignmentValidator should be activated to look at the
  # has_enough_drivers flag on the ride request.
  def prevent_destroy
    errors.add(:base, "Driver assignments cannot be destroyed")
    throw(:abort)
  end
end
