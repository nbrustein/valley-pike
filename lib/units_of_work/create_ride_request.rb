module UnitsOfWork
  class CreateRideRequest < UnitOfWork
    attr_reader :organization_id, :draft,
      :short_description, :date, :requires_multiple_drivers, :desired_driver_gender, :appointment_time

    def initialize(executor_id:, params:)
      super
      @organization_id = params.fetch(:organization_id)
      @short_description = params[:short_description]
      @date = params[:date]
      @requires_multiple_drivers = params[:requires_multiple_drivers] || false
      @desired_driver_gender = params[:desired_driver_gender].presence || "none"
      @appointment_time = params[:appointment_time]
    end

    private

    def execute_unit_of_work(errors:)
      @draft = RideRequest::Draft.new(
        organization_id:,
        requester_id: executor_id,
        draft: true,
        short_description:,
        date:,
        requires_multiple_drivers:,
        desired_driver_gender:,
        appointment_time:
      )
      return if @draft.save

      merge_errors(errors, @draft)
    end

    def merge_errors(errors, record)
      record.errors.each do |error|
        errors.add(error.attribute, error.message)
      end
    end
  end
end
