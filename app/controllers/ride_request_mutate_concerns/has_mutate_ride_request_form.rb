module RideRequestMutateConcerns
  module HasMutateRideRequestForm
    extend ActiveSupport::Concern
    include Memery

    FORM_STEP_COMPONENTS = {
      1 => RideRequestMutate::FormStep1Component,
      2 => RideRequestMutate::FormStep2Component,
      3 => RideRequestMutate::FormStep3Component,
      4 => RideRequestMutate::FormStep4Component,
      5 => RideRequestMutate::FormStep5Component,
    }.freeze
    FORM_STEP_COUNT = FORM_STEP_COMPONENTS.size

    def render_form(mode:, page:, ride_request:, submitted_params:, status: :ok)
      raise ArgumentError, "invalid mode" unless %i[create].include?(mode)

      setup_instance_vars(mode:, ride_request:, page:)
      render :form, status:
    end

    private

    def setup_instance_vars(mode:, ride_request:, page:)
      if mode == :create
        @form_action = if page == FORM_STEP_COUNT && ride_request&.id
          publish_ride_request_path(id: ride_request.id)
        elsif ride_request&.id
          edit_ride_request_path(id: ride_request.id, page:)
        else
          ride_requests_path
        end
        @form_method = page == FORM_STEP_COUNT ? :post : (ride_request&.id ? :patch : :post)
        @multi_page_form = MultiPageFormComponent.new(
          page_paths: create_page_paths(ride_request),
          current_page: page,
          last_page_label: ride_request&.draft? ? "Publish" : nil,
          destructive_action: destructive_action_for(ride_request)
        )
        @header_text = ride_request&.short_description.presence || "New Ride Request"
        @form_step_class = FORM_STEP_COMPONENTS.fetch(page)
        @form_step_attrs = {total_steps: FORM_STEP_COUNT}.merge(
          case page
          when 1 then {organizations: permitted_organizations, ride_request:}
          when 2 then {ride_request:}
          when 3 then {ride_request:}
          when 4 then {ride_request:, requester: ride_request&.requester}
          when 5 then {ride_request:}
          else {}
          end
        )
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

    def destructive_action_for(ride_request)
      return unless ride_request&.id

      if ride_request.draft?
        {
          label: "Delete Draft",
          path: delete_draft_ride_request_path(id: ride_request.id),
          method: :delete,
          confirm: "Are you sure you want to delete this draft?",
        }
      elsif ride_request.cancellable?
        {
          label: "Cancel Request",
          path: cancel_ride_request_path(id: ride_request.id),
          method: :post,
          confirm: "Are you sure you want to cancel this request?",
        }
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
