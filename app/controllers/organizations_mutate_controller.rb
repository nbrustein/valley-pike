class OrganizationsMutateController < ApplicationController
  include Memery
  include ExecutesUnitsOfWork
  include OrganizationMutateConcerns::HasMutateOrganizationForm

  def new
    authorize(nil, :new?, policy_class: OrganizationMutatePolicy)
    render_form mode: :create, target_organization: nil, submitted_params: nil
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
      target_organization: nil,
      submitted_params: create_organization_params
    )
  end

  def edit
    return render_not_found unless target_organization.present?

    authorize(target_organization, :edit?, policy_class: OrganizationMutatePolicy)
    render_form mode: :edit, target_organization:, submitted_params: nil
  end

  def update
    return render_not_found unless target_organization.present?

    success, _errors = execute_unit_of_work(
      policy_meth: :update?,
      policy_class: OrganizationMutatePolicy
    ) do
      UnitsOfWork::UpdateOrganization.new(
        executor_id: current_user.id,
        params: update_organization_params
      )
    end
    return redirect_to organizations_path, notice: "Organization updated." if success

    render_form(
      status: :unprocessable_entity,
      mode: :edit,
      target_organization:,
      submitted_params: update_organization_params
    )
  end

  private

  def create_organization_params
    permitted = params.require(:organization).permit(
      :name,
      :abbreviation,
      required_qualifications: []
    )
    normalize_organization_params(permitted)
  end

  def update_organization_params
    permitted = params.require(:organization).permit(
      :name,
      :abbreviation,
      required_qualifications: []
    )
    normalize_organization_params(permitted).merge(id: params[:id])
  end

  def normalize_organization_params(permitted)
    {
      name: permitted[:name],
      abbreviation: permitted[:abbreviation],
      required_qualifications: Array(permitted[:required_qualifications]).compact_blank.uniq,
    }
  end

  memoize def target_organization
    Organization.find_by(id: params[:id])
  end
end
