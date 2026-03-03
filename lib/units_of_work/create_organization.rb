module UnitsOfWork
  class CreateOrganization < UnitOfWork
    include Memery

    attr_reader :name, :abbreviation, :required_qualifications

    def initialize(executor_id:, params:)
      super
      @name = params.fetch(:name)
      @abbreviation = params.fetch(:abbreviation)
      @required_qualifications = Array(params.fetch(:required_qualifications, [])).compact_blank.uniq
    end

    private

    attr_reader :name, :abbreviation, :required_qualifications

    def execute_unit_of_work(errors:)
      organization = Organization.new
      organization.name = name
      organization.abbreviation = abbreviation
      organization.required_qualifications = required_qualifications
      return if organization.save

      merge_errors(errors, organization)
    end

    def merge_errors(errors, record)
      record.errors.each do |error|
        errors.add(error.attribute, error.message)
      end
    end
  end
end
