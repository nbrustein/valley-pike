module OrganizationMutateConcerns
  module HasMutateOrganizationForm
    extend ActiveSupport::Concern
    include Memery

    def render_form(status: :ok, submitted_params:, mode:)
      raise ArgumentError, "invalid mode" unless %i[ create ].include?(mode)
      setup_instance_vars(mode:)
      setup_input_defaults(submitted_params:)
      render :mutate, status:
    end

    def setup_instance_vars(mode:)
      if mode == :create
        @submit_text ||= "Create organization"
        @header_text ||= "Create organization"
        @subheader_text ||= "Add a new organization."
        @form_action ||= organizations_path
        @form_method ||= :post
      end
    end

    def setup_input_defaults(submitted_params:)
      @name = get_input_default(submitted_params:, key: :name)
      @abbreviation = get_input_default(submitted_params:, key: :abbreviation)
      @required_qualifications = Array(get_input_default(submitted_params:, key: :required_qualifications))
        .compact_blank
    end

    def get_input_default(submitted_params:, key:)
      return submitted_params.dig(key) if submitted_params.present?

      nil
    end
  end
end
