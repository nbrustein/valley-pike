class DriverRideRequestShowComponent < ViewComponent::Base
  def initialize(ride_request:)
    @ride_request = ride_request
  end

  private

  def formatted_date
    @ride_request.date.strftime("%B %-d, %Y")
  end

  def formatted_gender_preference
    case @ride_request.desired_driver_gender
    when "female"
      "Female driver requested"
    when "female_accompaniment"
      "Female accompaniment requested"
    else
      nil
    end
  end

  def status_label
    @ride_request.status_display[:label]
  end

  def format_address(address)
    return nil if address.blank?

    parts = [ address.street_address, address.city, address.state ]
    parts << address.zip if address.zip.present?
    parts.join(", ")
  end
end
