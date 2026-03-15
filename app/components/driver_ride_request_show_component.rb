class DriverRideRequestShowComponent < ViewComponent::Base
  def initialize(ride_request:, current_user:)
    @ride_request = ride_request
    @current_user = current_user
  end

  private

  def formatted_date
    @ride_request.date.strftime("%B %-d, %Y")
  end

  def formatted_gender_preference
    case @ride_request.desired_driver_gender
    when "female"
      "We are looking for a female driver for this ride."
    when "female_accompaniment"
      "We are looking for a female driver or a male driver with a female accompaniment for this ride."
    else
      nil
    end
  end

  def driver_status
    return {label: "Canceled", icon: "fa-ban"} if @ride_request.cancelled?
    return {label: "Complete", icon: "fa-circle-check"} if @ride_request.completed?

    if assigned_to_current_user?
      return {label: "You are assigned to this ride", icon: "fa-user-check"}
    end

    if @ride_request.driver_assignments.any?
      unless @ride_request.has_enough_drivers?
        return {label: "Looking for more drivers", icon: "fa-user-plus"}
      end
      return {label: "Driver assigned", icon: "fa-car"}
    end

    {label: "Looking for a driver", icon: "fa-user"}
  end

  def assigned_to_current_user?
    @ride_request.driver_assignments.any? {|da| da.driver_id == @current_user.id }
  end

  def format_address(address)
    return nil if address.blank?

    parts = [ address.street_address, address.city, address.state ]
    parts << address.zip if address.zip.present?
    parts.join(", ")
  end
end
