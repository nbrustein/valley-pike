class UsersController < ApplicationController
  include Memery

  def index
    authorize User, :index?
    @users = policy_scope(User)
  end

  def new
    @user = User.new
    authorize User, :create?
    @selected_organization_id = nil
    load_form_organizations
  end

  def create
    @user = User.new
    @user.email = create_user_params.fetch(:email)
    @user.user_roles.build(
      role: create_user_params[:role],
      organization_id: create_user_params[:organization_id]
    )
    authorize @user
    @selected_organization_id = create_user_params[:organization_id]
    load_form_organizations

    result = UnitsOfWork::CreateUser.execute(
      executor_id: current_user.id,
      params: {
        email: @user.email,
        full_name: "Unknown",
        phone: "",
        sortable_name: "Unknown",
        roles: @user.user_roles.map {|user_role| {role: user_role.role, organization_id: user_role.organization_id} }
      }
    )

    if result.success?
      redirect_to users_path, notice: "User created."
    else
      @errors = result.errors
      render :new, status: :unprocessable_entity
    end
  end

  private

  def load_form_organizations
    @organizations = Organization.where(id: permitted_org_ids_for_creation).order(:name)
    @default_organization_id = permitted_org_ids_for_creation.first
  end

  def create_user_params
    params.require(:user).permit(:email, :organization_id, :role)
  end

  memoize def permitted_org_ids_for_creation
    policy(User).permitted_org_ids_for_role_management
  end

  def set_errors(attribute, message)
    @errors = ActiveModel::Errors.new(@user)
    @errors.add(attribute, message)
  end
end
