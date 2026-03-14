module UnitsOfWork
  class CancelRideRequest < UnitOfWork
    def initialize(executor_id:, params:)
      super
      @ride_request_id = params.fetch(:ride_request_id)
    end

    private

    def execute_unit_of_work(errors:)
      ride_request = RideRequest.find_by(id: @ride_request_id)
      unless ride_request
        errors.add(:base, "Ride request not found")
        return
      end

      ride_request.cancelled = true
      return if ride_request.save

      ride_request.errors.each {|error| errors.add(error.attribute, error.message) }
    end
  end
end
