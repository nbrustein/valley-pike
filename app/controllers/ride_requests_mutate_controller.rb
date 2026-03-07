class RideRequestsMutateController < ApplicationController
  include Memery
  include ExecutesUnitsOfWork
  include RideRequestMutateConcerns::HasMutateRideRequestForm

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

    render_form(status: :unprocessable_entity, mode: :create, page: 1, ride_request: nil, submitted_params: create_ride_request_params)
  end

  # GET /ride_requests/:id/edit(/:page)
  def edit
    return render_not_found unless target_ride_request.present?

    authorize(target_ride_request, :edit?, policy_class: RideRequestMutatePolicy)
    render_form(mode: :create, page: params.fetch(:page, 1).to_i, ride_request: target_ride_request, submitted_params: nil)
  end

  # PATCH /ride_requests/:id/edit(/:page)
  def update
    return render_not_found unless target_ride_request.present?

    authorize(target_ride_request, :edit?, policy_class: RideRequestMutatePolicy)

    # FIXME: implement a UOW
    current_page = params[:page].to_i
    next_path = current_page >= PAGE_COUNT ? ride_requests_path : edit_ride_request_path(id: target_ride_request.id, page: current_page + 1)
    redirect_to next_path
  end

  private

  def create_ride_request_params
    {organization_id: RideRequestMutatePolicy.new(current_user, nil).permitted_organization_ids.first}
  end

  memoize def target_ride_request
    RideRequest.find_by(id: params[:id])
  end
end
