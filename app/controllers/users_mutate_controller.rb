class UsersMutateController < ApplicationController
  include Memery
  include ExecutesUnitsOfWork
  include UserMutateConcerns::HasMutateUserForm
  helper UsersHelper

  def show
    return render_not_found unless target_user.present?

    authorize(target_user, :show?, policy_class: UserViewPolicy)
    render_form mode: :show, target_user:, submitted_params: nil
  end

  def new
    authorize(nil, :new?, policy_class: UserMutatePolicy)
    render_form mode: :create, target_user: nil, submitted_params: nil
  end

  def create
    success, errors = execute_unit_of_work(
      policy_meth: :create?,
      policy_class: UserMutatePolicy
    ) do
      UnitsOfWork::CreateUser.new(
        executor_id: current_user.id,
        params: create_user_params
      )
    end
    return redirect_to users_path, notice: "User created." if success

    render_form(
      status: :unprocessable_entity,
      mode: :create,
      target_user: nil,
      submitted_params: create_user_params
    )
  end

  def edit
    return render_not_found unless target_user.present?
    authorize(target_user, :edit?, policy_class: UserMutatePolicy)
    render_form mode: :edit, target_user:, submitted_params: nil
  end

  def update
    return render_not_found unless target_user.present?

    success, _errors = execute_unit_of_work(
      policy_meth: :update?,
      policy_class: UserMutatePolicy
    ) do
      UnitsOfWork::UpdateUser.new(
        executor_id: current_user.id,
        params: update_user_params
      )
    end
    return redirect_to users_path, notice: "User updated." if success

    render_form(
      status: :unprocessable_entity,
      mode: :edit,
      target_user:,
      submitted_params: update_user_params
    )
  end

  def send_login_link
    return render_not_found unless target_user.present?

    authorize(target_user, :edit?, policy_class: UserMutatePolicy)
    success, errors = execute_unit_of_work(
    ) do
      UnitsOfWork::SendUserLoginLink.new(
        executor_id: current_user.id,
        params: {user_id: target_user.id}
      )
    end

    if success
      redirect_to users_path, notice: "Login link sent."
    else
      error_message = errors.full_messages.presence&.to_sentence || "Unable to send login link."
      redirect_to users_path, alert: error_message
    end
  end

  private

  memoize def user_mutate_policy
    UserMutatePolicy.new(current_user, nil)
  end

  def create_user_params
    permitted = params.require(:user).permit(
      :email,
      :full_name,
      :preferred_name,
      :phone,
      :global_role,
      :driver_role,
      :send_login_link,
      driver_qualifications: [],
      org_admin_user_roles: %i[role organization_id]
    )
    normalized_user_params(permitted)
  end

  def update_user_params
    permitted = params.require(:user).permit(
      :email,
      :full_name,
      :preferred_name,
      :phone,
      :disabled,
      :global_role,
      :driver_role,
      driver_qualifications: [],
      org_admin_user_roles: %i[role organization_id]
    )
    normalized_user_params(permitted).merge(id: params[:id])
  end

  def normalized_user_params(permitted)
    user_roles = normalize_user_roles(
      org_admin_user_roles: permitted[:org_admin_user_roles],
      global_role: permitted[:global_role],
      driver_role: permitted[:driver_role]
    )
    extra_attrs = {
      user_roles:,
      driver_qualifications: normalize_driver_qualifications(permitted[:driver_qualifications]),
      send_login_link: ActiveModel::Type::Boolean.new.cast(permitted[:send_login_link]),
    }
    extra_attrs[:disabled] = cast_boolean(permitted[:disabled]) if permitted.key?(:disabled)
    permitted
      .to_h
      .except("global_role", "org_admin_user_roles", "driver_role")
      .deep_symbolize_keys
      .merge(extra_attrs)
  end

  def normalize_user_roles(org_admin_user_roles:, global_role:, driver_role:)
    normalize_org_admin_user_roles(org_admin_user_roles) +
      normalize_global_user_roles(global_role) +
      normalize_driver_user_roles(driver_role)
  end

  def normalize_org_admin_user_roles(org_admin_user_roles)
    return [] if org_admin_user_roles.blank?

    # The inputs for org_admin_user_roles are a list of radio inputs,
    # so they end up here as a hash whose values are hashes, but we want
    # an array of hashes.
    org_admin_user_roles.values.filter_map do |entry|
      role = entry["role"] || entry[:role]
      organization_id = entry["organization_id"] || entry[:organization_id]
      next if role.blank?

      {role:, organization_id:}
    end
  end

  def normalize_global_user_roles(global_role)
    return [] if global_role.blank?

    [ {role: global_role, organization_id: nil} ]
  end

  def normalize_driver_user_roles(driver_role)
    return [] if driver_role != UserRole::DRIVER

    [ {role: UserRole::DRIVER, organization_id: nil} ]
  end

  def normalize_driver_qualifications(driver_qualifications)
    Array(driver_qualifications).compact_blank.uniq
  end

  memoize def target_user
    User.find_by(id: params[:id])
  end
end
