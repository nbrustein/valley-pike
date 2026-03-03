module UnitsOfWork
  class UpdateOrganization < UnitOfWork
    include Memery

    attr_reader :organization_id, :name, :abbreviation, :required_qualifications
    attr_reader :has_name_key, :has_abbreviation_key, :has_required_qualifications_key

    def initialize(executor_id:, params:)
      super
      @organization_id = params.fetch(:id)
      @name = params[:name]
      @abbreviation = params[:abbreviation]
      @required_qualifications = params[:required_qualifications]
      @has_name_key = params.key?(:name)
      @has_abbreviation_key = params.key?(:abbreviation)
      @has_required_qualifications_key = params.key?(:required_qualifications)
    end

    memoize def organization
      Organization.find_by(id: organization_id)
    end

    private

    attr_reader :organization_id, :name, :abbreviation, :required_qualifications
    attr_reader :has_name_key, :has_abbreviation_key, :has_required_qualifications_key

    def execute_unit_of_work(errors:)
      organization = self.organization
      if organization.nil?
        errors.add(:base, "Organization not found")
        return
      end

      update_organization(organization, errors)
    end

    def update_organization(organization, errors)
      organization.name = name if has_name_key
      organization.abbreviation = abbreviation if has_abbreviation_key
      if has_required_qualifications_key
        organization.required_qualifications = Array(required_qualifications).compact_blank.uniq
      end
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
