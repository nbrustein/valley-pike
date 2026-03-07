class RideRequest::Draft < RideRequest
  extend Validations::BooleanValidators

  validates_truth_of :draft
end
