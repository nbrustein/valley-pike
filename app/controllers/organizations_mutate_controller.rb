class OrganizationsMutateController < ApplicationController
  include Memery
  include ExecutesUnitsOfWork
  include OrganizationMutateConcerns::HasMutateOrganizationForm

  def new
    authorize(nil, :new?, policy_class: OrganizationMutatePolicy)
    render_form mode: :create, submitted_params: nil
  end

  def create
    success, _errors = execute_unit_of_work(
      policy_meth: :create?,
      policy_class: OrganizationMutatePolicy
    ) do
      UnitsOfWork::CreateOrganization.new(
        executor_id: current_user.id,
        params: create_organization_params
      )
    end
    return redirect_to organizations_path, notice: "Organization created." if success

    render_form(
      status: :unprocessable_entity,
      mode: :create,
      submitted_params: create_organization_params
    )
  end

  private

  def create_organization_params
    params.require(:organization).permit(
      :name,
      :abbreviation,
      required_qualifications: []
    ).to_h.deep_symbolize_keys
  end
end
