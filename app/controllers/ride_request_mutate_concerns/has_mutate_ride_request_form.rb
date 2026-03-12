module RideRequestMutateConcerns
  module HasMutateRideRequestForm
    extend ActiveSupport::Concern
    include Memery

    FORM_STEP_COUNT = 5
    FORM_STEP_COMPONENTS = {
      1 => RideRequestMutate::FormStep1Component,
      2 => RideRequestMutate::FormStep2Component,
      3 => RideRequestMutate::FormStep3Component,
      4 => RideRequestMutate::FormStep4Component,
      5 => RideRequestMutate::FormStep5Component,
    }.freeze

    def render_form(mode:, page:, ride_request:, submitted_params:, status: :ok)
      raise ArgumentError, "invalid mode" unless %i[create].include?(mode)

      setup_instance_vars(mode:, ride_request:, page:)
      render :form, status:
    end

    private

    def setup_instance_vars(mode:, ride_request:, page:)
      if mode == :create
        @form_action = ride_request&.id ? edit_ride_request_path(id: ride_request.id, page:) : ride_requests_path
        @form_method = ride_request&.id ? :patch : :post
        @multi_page_form = MultiPageFormComponent.new(
          page_paths: create_page_paths(ride_request),
          current_page: page,
          last_page_label: "Publish"
        )
        @header_text = ride_request&.short_description.presence || "New Ride Request"
        @form_step_class = FORM_STEP_COMPONENTS.fetch(page)
        @form_step_attrs = case page
        when 1 then {organizations: permitted_organizations, ride_request:}
        when 2 then {ride_request:}
        when 3 then {ride_request:}
        when 4 then {ride_request:, requester: ride_request&.requester}
        else {}
        end
      end
    end

    memoize def permitted_organizations
      policy = RideRequestMutatePolicy.new(current_user, nil)
      if policy.all_organizations_permitted?
        Organization.all.to_a
      else
        Organization.where(id: policy.permitted_organization_ids.compact).to_a
      end
    end

    def create_page_paths(ride_request)
      id = ride_request&.id
      [
        id ? edit_ride_request_path(id:) : new_ride_request_path,
        *(2..FORM_STEP_COUNT).map {|p| id ? edit_ride_request_path(id:, page: p) : nil },
      ]
    end
  end
end
