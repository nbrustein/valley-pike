module UnitsOfWork
  class CreateRideRequest < UnitOfWork
    attr_reader :organization_id, :draft

    def initialize(executor_id:, params:)
      super
      @organization_id = params.fetch(:organization_id)
    end

    private

    def execute_unit_of_work(errors:)
      @draft = RideRequest::Draft.new(
        organization_id:,
        requester_id: executor_id,
        draft: true
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
