class UsersMutateController < ApplicationController
  include Memery
  helper UsersHelper

  def new
    authorize(nil, :new?, policy_class: UserMutatePolicy)
    @user = User.new
    render_form
  end

  def create
    begin
      result = execute_create_user_unit_of_work
      if result.success?
        redirect_to users_path, notice: "User created."
        return
      else
        @errors = result.errors
      end
    rescue Pundit::NotAuthorizedError
      raise
    rescue StandardError
      @errors = ActiveModel::Errors.new(User.new)
      @errors.add(:base, "An error occurred")
    end

    setup_create_instance_vars
    render_form status: :unprocessable_entity
  end

  private

  def execute_create_user_unit_of_work
    uow = UnitsOfWork::CreateUser.new(
      executor_id: current_user.id,
      params: create_user_params
    )
    authorize(uow, :create?, policy_class: UserMutatePolicy)
    uow.execute
  end

  memoize def user_mutate_policy
    UserMutatePolicy.new(current_user, nil)
  end

  memoize def setup_instance_vars
    @roles_for_global_role_input = [ UserRole::DEVELOPER, UserRole::VANITA_ADMIN, UserRole::VANITA_VIEWER ] & user_mutate_policy.manageable_roles
    @roles_for_org_role_inputs = [ UserRole::ORG_ADMIN, UserRole::RIDE_REQUESTER ] & user_mutate_policy.manageable_roles
    @organizations_for_org_role_inputs = UserMutatePolicy::OrganizationScope.new(current_user, nil).resolve
  end

  # when we are rendering the form after a submission led to an error, we want to fill in fields
  # with the inputted values
  memoize def setup_create_instance_vars
    @email = create_user_params&.dig(:email)
  end

  memoize def render_form(status: :ok)
    setup_instance_vars
    render :mutate, status:
  end

  def create_user_params
    permitted = params.require(:user).permit(
      :email,
      :global_role,
      org_admin_user_roles: %i[role organization_id]
    )
    user_roles = normalize_user_roles(
      org_admin_user_roles: permitted[:org_admin_user_roles],
      global_role: permitted[:global_role]
    )
    permitted.to_h.except("global_role", "org_admin_user_roles").merge(
      full_name: "John Doe",
      phone: "",
      sortable_name: "Doe, John",
      user_roles:
    )
  end

  def normalize_user_roles(org_admin_user_roles:, global_role:)
    normalize_org_admin_user_roles(org_admin_user_roles) +
      normalize_global_user_roles(global_role)
  end

  def normalize_org_admin_user_roles(org_admin_user_roles)
    return [] if org_admin_user_roles.blank?

    # The inputs for org_admin_user_roles are a list of radio inputs,
    # so they end up here as a hash whose values are hashes, but we want
    # an array of hashes.
    org_admin_user_roles.values.filter_map do |entry|
      role = entry[:role]
      organization_id = entry[:organization_id]
      next if role.blank?

      {role:, organization_id:}
    end
  end

  def normalize_global_user_roles(global_role)
    return [] if global_role.blank?

    [ {role: global_role, organization_id: nil} ]
  end
end
