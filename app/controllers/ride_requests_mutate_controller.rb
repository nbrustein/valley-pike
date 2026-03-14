class RideRequestsMutateController < ApplicationController
  include Memery
  include ExecutesUnitsOfWork
  include RideRequestMutateConcerns::HasMutateRideRequestForm
  include CastsParams

  # GET /ride_requests/new
  def new
    authorize(nil, :new?, policy_class: RideRequestMutatePolicy)
    render_form(mode: :create, page: 1, ride_request: nil, submitted_params: nil)
  end

  # POST /ride_requests
  def create
    uow = nil
    success, _errors = execute_unit_of_work(
      policy_meth: :create?,
      policy_class: RideRequestMutatePolicy
    ) do
      # FIXEM: include the record in the result
      uow = UnitsOfWork::CreateRideRequest.new(
        executor_id: current_user.id,
        params: create_ride_request_params
      )
    end
    return redirect_to edit_ride_request_path(id: uow.draft.id, page: 2) if success

    render_form(
      status: :unprocessable_entity, mode: :create, page: 1,
      ride_request: uow&.draft, submitted_params: create_ride_request_params
    )
  end

  # GET /ride_requests/:id/edit(/:page)
  def edit
    return render_not_found unless target_ride_request.present?

    authorize(target_ride_request, :edit?, policy_class: RideRequestMutatePolicy)
    render_form(mode: :create, page: params.fetch(:page, 1).to_i, ride_request: target_ride_request,
      submitted_params: nil)
  end

  # PATCH /ride_requests/:id/edit(/:page)
  def update
    return render_not_found unless target_ride_request.present?

    authorize(target_ride_request, :edit?, policy_class: RideRequestMutatePolicy)

    current_page = params[:page].to_i
    uow = nil
    success, _errors = execute_unit_of_work do
      uow = UnitsOfWork::UpdateRideRequest.new(
        executor_id: current_user.id,
        params: update_ride_request_params.merge(id: params[:id])
      )
    end

    return redirect_to edit_ride_request_path(id: target_ride_request.id, page: current_page + 1) if success

    render_form(
      status: :unprocessable_entity, mode: :create, page: current_page,
      ride_request: uow&.ride_request, submitted_params: update_ride_request_params
    )
  end

  # POST /ride_requests/:id/publish
  def publish
    return render_not_found unless target_ride_request.present?

    authorize(target_ride_request, :edit?, policy_class: RideRequestMutatePolicy)

    uow = nil
    success, _errors = execute_unit_of_work do
      uow = UnitsOfWork::PublishRideRequest.new(
        executor_id: current_user.id,
        params: {ride_request_id: params[:id]}
      )
    end

    return redirect_to ride_requests_path if success

    render_form(
      status: :unprocessable_entity, mode: :create, page: FORM_STEP_COUNT,
      ride_request: target_ride_request, submitted_params: nil
    )
  end

  private

  def update_ride_request_params
    permitted = params.require(:ride_request).permit(
      :organization_id,
      :short_description,
      :date,
      :requires_multiple_drivers,
      :desired_driver_gender,
      :appointment_time,
      :ride_description_public,
      :ride_description_private,
      :contact_full_name,
      :contact_phone,
      :contact_email,
      pick_up_address: %i[name street_address city state],
      destination_address: %i[name street_address city state]
    ).to_h.deep_symbolize_keys
    if permitted.key?(:requires_multiple_drivers)
      permitted[:requires_multiple_drivers] = cast_boolean(params.dig(:ride_request, :requires_multiple_drivers))
    end
    permitted
  end

  def create_ride_request_params
    params.require(:ride_request).permit(
      :organization_id,
      :short_description,
      :date,
      :requires_multiple_drivers,
      :desired_driver_gender,
      :appointment_time
    ).to_h.symbolize_keys.merge(
      requires_multiple_drivers: cast_boolean(params.dig(:ride_request, :requires_multiple_drivers))
    )
  end

  memoize def target_ride_request
    RideRequest.find_by(id: params[:id])
  end
end
