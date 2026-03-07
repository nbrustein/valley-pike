module UnitsOfWork
  class PublishRideRequest < UnitOfWork
    def initialize(executor_id:, params:)
      super
      @ride_request_id = params.fetch(:ride_request_id)
    end

    private

    attr_reader :ride_request_id

    def execute_unit_of_work(errors:)
      ride_request = RideRequest.find_by(id: ride_request_id)

      unless ride_request
        errors.add(:base, "Ride request not found")
        return
      end

      if ride_request.is_a?(RideRequest::Published)
        errors.add(:base, "Ride request is already published")
        return
      end

      published = ride_request.becomes(RideRequest::Published)
      published.type = "RideRequest::Published"
      published.draft = false

      return if published.save

      published.errors.each do |error|
        errors.add(error.attribute, error.message)
      end
    end
  end
end
