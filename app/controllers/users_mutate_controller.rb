class UsersMutateController < ApplicationController
  include Memery
  helper UsersHelper

  def new
    authorize(nil, :new?, policy_class: UserMutatePolicy)
    @user = User.new
    render_form
  end

  def create
    uow = UnitsOfWork::CreateUser.new(
      executor_id: current_user.id,
      params: create_user_params
    )
    authorize(uow, :create?, policy_class: UserMutatePolicy)
    result = uow.execute
    if result.success?
      redirect_to users_path, notice: "User created."
    else
      @errors = result.errors
      setup_create_instance_vars
      render_form status: :unprocessable_entity
    end
  end

  private

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
      org_admin_user_roles: %i[role organization_id]
    )
    user_roles = normalize_user_roles(permitted[:org_admin_user_roles])
    permitted.to_h.merge(
      full_name: "John Doe",
      phone: "",
      sortable_name: "Doe, John",
      user_roles:
    )
  end

  def normalize_user_roles(org_admin_user_roles)
    return [] if org_admin_user_roles.blank?

    # The inputs for org_admin_user_roles area list of radio inputs,
    # so they end up here as a hash whose values are hashes, but we want 
    # an array of hashes
    org_admin_user_roles.values.filter_map do |entry|
      role = entry[:role]
      organization_id = entry[:organization_id]
      next if role.blank?

      {role:, organization_id:}
    end
  end
end
