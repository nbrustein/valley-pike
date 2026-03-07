module OrganizationMutateConcerns
  module HasMutateOrganizationForm
    extend ActiveSupport::Concern
    include Memery

    def render_form(status: :ok, target_organization:, submitted_params:, mode:)
      raise ArgumentError, "invalid mode" unless %i[ create edit show ].include?(mode)
      @readonly = mode == :show
      setup_instance_vars(mode:, target_organization:)
      setup_input_defaults(target_organization:, submitted_params:)
      render :mutate, status:
    end

    def setup_instance_vars(mode:, target_organization:)
      if mode == :create
        @submit_text ||= "Create organization"
        @header_text ||= "Create organization"
        @subheader_text ||= "Add a new organization."
        @form_action ||= organizations_path
        @form_method ||= :post
      elsif mode == :show
        @header_text ||= target_organization.name
        @subheader_text ||= "Organization details."
        @form_action ||= organization_path(id: target_organization.id)
        @form_method ||= :patch
      elsif mode == :edit
        @submit_text ||= "Update organization"
        @header_text ||= "Edit organization"
        @subheader_text ||= "Update organization details."
        @form_action ||= organization_path(id: target_organization.id)
        @form_method ||= :patch
      else
        raise "invalid mode"
      end
    end

    def setup_input_defaults(target_organization:, submitted_params:)
      @name = get_input_default(target_organization:, submitted_params:, key: :name)
      @abbreviation = get_input_default(target_organization:, submitted_params:, key: :abbreviation)
      @required_qualifications = Array(get_input_default(target_organization:, submitted_params:, key: :required_qualifications))
        .compact_blank
    end

    def get_input_default(target_organization:, submitted_params:, key:)
      return submitted_params.dig(key) if submitted_params.present?
      return target_organization.send(key) if target_organization.present?

      nil
    end
  end
end
