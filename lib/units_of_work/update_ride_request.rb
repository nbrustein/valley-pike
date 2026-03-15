module UnitsOfWork
  class UpdateRideRequest < UnitOfWork
    attr_reader :ride_request

    def initialize(executor_id:, params:)
      super
      @ride_request_id = params.fetch(:id)
      @pick_up_address_attrs = params.delete(:pick_up_address)
      @destination_address_attrs = params.delete(:destination_address)
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

      if @pick_up_address_attrs
        address = upsert_address(:pick_up_address, @pick_up_address_attrs, errors)
        return if errors.any?

        @ride_request.pick_up_address = address
      end

      if @destination_address_attrs
        address = upsert_address(:destination_address, @destination_address_attrs, errors)
        return if errors.any?

        @ride_request.destination_address = address
      end

      validator = RideRequestAssignmentValidator.new(ride_requests: [ @ride_request ])
      unless validator.validate
        validator.errors.each {|e| errors.add(e.attribute, e.message) }
        return
      end

      return if @ride_request.save

      merge_errors(errors, @ride_request)
    end

    def upsert_address(association, address_attrs, errors)
      attrs = address_attrs.slice(:name, :street_address, :city, :state)
      return nil if attrs.values.all?(&:blank?)

      attrs[:country] = "US"

      address = @ride_request.public_send(association) || Address.new
      address.assign_attributes(attrs)
      return address if address.save

      merge_errors(errors, address)
      nil
    end

    def merge_errors(errors, record)
      record.errors.each do |error|
        errors.add(error.attribute, error.message)
      end
    end
  end
end
