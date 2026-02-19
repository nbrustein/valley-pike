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

  memoize def roles_for_global_role_input
    [ UserRole::DEVELOPER, UserRole::VANITA_ADMIN, UserRole::VANITA_VIEWER ] & user_mutate_policy.manageable_roles
  end

  memoize def setup_instance_vars
    @roles_for_global_role_input = roles_for_global_role_input
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

  # memoize def permitted_roles
  #   user_mutate_policy.permits_users_with_roles
  # end

  # memoize def permitted_organizations
  #   UserMutatePolicy::OrganizationScope.new(current_user, nil).resolve
  # end

  # memoize def default_organization
  #   permitted_organizations.size == 1 ? permitted_organizations.first.id : nil
  # end

  def create_user_params
    params.require(:user).permit(
      :email,
      user_roles: %i[role organization_id]
    ).merge(
      full_name: "John Doe",
      phone: "",
      sortable_name: "Doe, John",
    )
  end
end
