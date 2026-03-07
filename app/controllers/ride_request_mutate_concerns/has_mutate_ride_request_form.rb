module RideRequestMutateConcerns
  module HasMutateRideRequestForm
    extend ActiveSupport::Concern
    include Memery

    PAGE_COUNT = 5
    PAGE_COMPONENTS = {
      1 => RideRequestMutate::Page1Component,
      2 => RideRequestMutate::Page2Component,
      3 => RideRequestMutate::Page3Component,
      4 => RideRequestMutate::Page4Component,
      5 => RideRequestMutate::Page5Component,
    }.freeze

    def render_form(mode:, page:, ride_request:, submitted_params:)
      raise ArgumentError, "invalid mode" unless %i[create].include?(mode)

      setup_instance_vars(mode:, ride_request:, page:)
      render :form
    end

    private

    def setup_instance_vars(mode:, ride_request:, page:)
      if mode == :create
        form_action = page == 1 ? ride_requests_path : edit_ride_request_path(id: ride_request.id, page:)
        form_method = page == 1 ? :post : :patch
        @multi_page_form = MultiPageFormComponent.new(
          form_action:,
          form_method:,
          page_paths: create_page_paths(ride_request),
          current_page: page,
          last_page_label: "Publish"
        )
        @page_component = PAGE_COMPONENTS.fetch(page).new
      end
    end

    def create_page_paths(ride_request)
      id = ride_request&.id
      [
        id ? edit_ride_request_path(id:) : new_ride_request_path,
        *(2..PAGE_COUNT).map {|p| id ? edit_ride_request_path(id:, page: p) : nil },
      ]
    end
  end
end
