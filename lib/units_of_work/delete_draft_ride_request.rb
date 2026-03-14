module UnitsOfWork
  class DeleteDraftRideRequest < UnitOfWork
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

      ride_request.destroy!
    end
  end
end
