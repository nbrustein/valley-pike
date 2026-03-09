module UnitsOfWork
  class UpdateRideRequest < UnitOfWork
    attr_reader :ride_request

    def initialize(executor_id:, params:)
      super
      @ride_request_id = params.fetch(:id)
      @attributes = params.except(:id)
    end

    private

    def execute_unit_of_work(errors:)
      @ride_request = RideRequest.find_by(id: @ride_request_id)
      if @ride_request.nil?
        errors.add(:base, "Ride request not found")
        return
      end

      @ride_request.assign_attributes(@attributes)
      return if @ride_request.save

      merge_errors(errors, @ride_request)
    end

    def merge_errors(errors, record)
      record.errors.each do |error|
        errors.add(error.attribute, error.message)
      end
    end
  end
end
