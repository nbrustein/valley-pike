module UnitsOfWork
  class CreateRideRequest < UnitOfWork
    attr_reader :organization_id

    def initialize(executor_id:, params:)
      super
      @organization_id = params.fetch(:organization_id)
    end

    private

    def execute_unit_of_work(errors:)
      raise NotImplementedError
    end
  end
end
