module UnitsOfWork
  class AcceptRideRequest < UnitOfWork
    def initialize(executor_id:, params:)
      super
      @ride_request_id = params.fetch(:ride_request_id)
    end

    private

    def execute_unit_of_work(errors:)
      ride_request = RideRequest.find_by(id: @ride_request_id)
      if ride_request.nil?
        errors.add(:base, "Ride request not found")
        return
      end

      unless ride_request.needs_more_drivers?(current_date: Date.current)
        errors.add(:base, "This ride is not looking for more drivers")
        return
      end

      assignment = DriverAssignment.new(ride_request:, driver_id: executor_id)

      validator = RideRequestAssignmentValidator.new(driver_assignments: [ assignment ])
      unless validator.validate
        validator.errors.each {|e| errors.add(e.attribute, e.message) }
        return
      end

      return if assignment.save

      merge_errors(errors, assignment)
    end

    def merge_errors(errors, record)
      record.errors.each do |error|
        errors.add(error.attribute, error.message)
      end
    end
  end
end
