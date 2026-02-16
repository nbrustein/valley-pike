class UsersController < ApplicationController
  def index
    authorize User, :index?
    @users = policy_scope(User)
  end

  def new
    authorize User, :create?
    @user = User.new
    @selected_organization_id = nil
    load_form_organizations
  end

  def create
    authorize User, :create?
    @user = User.new(email: create_user_params.fetch(:email))
    @selected_organization_id = create_user_params[:organization_id]
    load_form_organizations

    organization_id = resolve_organization_id
    if organization_id.blank?
      set_errors(:organization, "is required")
      return render(:new, status: :unprocessable_entity)
    end

    result = UnitsOfWork::CreateUser.execute(
      executor_id: current_user.id,
      params: {
        email: @user.email,
        full_name: "Unknown",
        phone: "",
        sortable_name: "Unknown",
        roles: [ {role: UserRole::RIDE_REQUESTER, organization_id:} ]
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
    @organizations = Organization.order(:name)
    @default_organization_id = permitted_org_ids_for_creation.first
  end

  def create_user_params
    params.require(:user).permit(:email, :organization_id, :role)
  end

  def resolve_organization_id
    return permitted_org_ids_for_creation.first unless can_select_organization?

    organization_id = create_user_params[:organization_id]
    return if organization_id.blank?
    return organization_id if permitted_org_ids_for_creation.include?(organization_id)

    set_errors(:organization, "is not allowed")
    nil
  end

  def can_select_organization?
    policy(User).can_create_ride_requesters_for_any_organization?
  end

  def permitted_org_ids_for_creation
    @permitted_org_ids_for_creation ||= policy(User).permitted_org_ids_for_ride_requester_creation
  end

  def set_errors(attribute, message)
    @errors = ActiveModel::Errors.new(@user)
    @errors.add(attribute, message)
  end
end
