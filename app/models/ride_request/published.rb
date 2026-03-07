class RideRequest::Published < RideRequest
  extend Validations::BooleanValidators

  validates_falsity_of :draft
  validates :date, :pick_up_address, :contact_full_name, :ride_description_public, :short_description, presence: true
  validates :short_description, length: {maximum: 61}, allow_blank: true
end
