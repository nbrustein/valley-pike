module UserMutateConcerns
  module HasMutateUserForm
    extend ActiveSupport::Concern
    include Memery

    # FIXME: continue moving stuff over here
    def render_form(status: :ok, target_user:, submitted_params:, mode:)
      raise ArgumentError, "invalid mode" unless %i[ create edit ].include?(mode)
      setup_instance_vars(mode:, target_user:)
      setup_input_defaults(target_user:, submitted_params:)
      render :mutate, status:
    end

    def setup_instance_vars(mode:, target_user:)
      @target_user = target_user
      @roles_for_global_role_input = [ UserRole::DEVELOPER, UserRole::VANITA_ADMIN, UserRole::VANITA_VIEWER ] & user_mutate_policy.manageable_roles
      @roles_for_org_role_inputs = [ UserRole::ORG_ADMIN, UserRole::RIDE_REQUESTER ] & user_mutate_policy.manageable_roles
      @organizations_for_org_role_inputs = Organization.all
      @show_driver_role_input = user_mutate_policy.manage_drivers?
      if mode == :create
        @submit_text ||= "Create ride requester"
        @header_text ||= "Create ride requester"
        @subheader_text ||= "Invite a new ride requester by email."
        @form_action ||= users_path
        @form_method ||= :post
        @show_send_login_link_checkbox = true
        @send_login_link = true
        @show_disable_input = false
      else
        @submit_text ||= "Update user"
        @header_text ||= "Edit user"
        @subheader_text ||= "Update user details and roles."
        @form_action ||= user_path(id: target_user.id)
        @form_method ||= :patch
        @show_send_login_link_checkbox = false
        @show_send_login_link_button = true
        @send_login_link_button_disabled = target_user.disabled?
        @show_disable_input = true
      end
    end

    def setup_input_defaults(target_user:, submitted_params:)
      @email = get_input_default(target_user:, submitted_params:, key: :email)
      @full_name = get_input_default(target_user:, submitted_params:, key: :full_name)
      @preferred_name = get_input_default(target_user:, submitted_params:, key: :preferred_name)
      @phone = get_input_default(target_user:, submitted_params:, key: :phone)
      @disabled = cast_boolean(get_input_default(target_user:, submitted_params:, key: :disabled))
      setup_role_defaults(target_user:, submitted_params:)
      setup_send_login_link_default(submitted_params:)
    end

    def get_input_default(target_user:, submitted_params:, key:)
      if target_user.present?
        return target_user.send(key) if target_user.respond_to?(key)
        return target_user.human.send(key) if target_user.human.respond_to?(key)
        raise "Cannot get value #{key.inspect} from target user"
      end
      return submitted_params.dig(key) if submitted_params.present?
      nil
    end

    def setup_role_defaults(target_user:, submitted_params:)
      if submitted_params.present?
        apply_role_defaults_from_user_roles(
          user_roles: submitted_params[:user_roles] || [],
          driver_qualifications: submitted_params[:driver_qualifications] || []
        )
        return
      end

      if target_user.present?
        apply_role_defaults_from_user(target_user)
        return
      end

      @selected_global_role = nil
      @selected_org_admin_roles = {}
      @selected_driver_role = false
      @selected_driver_qualifications = []
    end

    def apply_role_defaults_from_user(target_user)
      roles = target_user.user_roles.to_a
      driver_qualifications = target_user.driver_qualifications.map(&:qualification)
      apply_role_defaults_from_user_roles(user_roles: roles, driver_qualifications:)
    end

    def apply_role_defaults_from_user_roles(user_roles:, driver_qualifications:)
      selected_global_role = user_roles.find do |role|
        role_organization_id(role).nil? && @roles_for_global_role_input.include?(role_name(role))
      end

      @selected_global_role = selected_global_role ? role_name(selected_global_role) : nil
      @selected_org_admin_roles = user_roles.each_with_object({}) do |role, acc|
        organization_id = role_organization_id(role)
        next if organization_id.nil?
        next unless @roles_for_org_role_inputs.include?(role_name(role))

        acc[organization_id] = role_name(role)
      end
      @selected_driver_role = user_roles.any? {|role| role_name(role) == UserRole::DRIVER }
      @selected_driver_qualifications = Array(driver_qualifications)
    end

    def setup_send_login_link_default(submitted_params:)
      return unless submitted_params.present?
      return unless submitted_params.key?(:send_login_link)

      @send_login_link = ActiveModel::Type::Boolean.new.cast(submitted_params[:send_login_link])
    end

    def role_name(role)
      role.respond_to?(:role) ? role.role : role[:role] || role["role"]
    end

    def role_organization_id(role)
      role.respond_to?(:organization_id) ? role.organization_id : role[:organization_id] || role["organization_id"]
    end
  end
end
