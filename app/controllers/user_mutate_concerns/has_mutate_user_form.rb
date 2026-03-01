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
      @roles_for_global_role_input = [ UserRole::DEVELOPER, UserRole::VANITA_ADMIN, UserRole::VANITA_VIEWER ] & user_mutate_policy.manageable_roles
      @roles_for_org_role_inputs = [ UserRole::ORG_ADMIN, UserRole::RIDE_REQUESTER ] & user_mutate_policy.manageable_roles
      @organizations_for_org_role_inputs = UserMutatePolicy::OrganizationScope.new(current_user, nil).resolve
      @show_driver_role_input = user_mutate_policy.manage_drivers?
      if mode == :create
        @submit_text ||= "Create ride requester"
        @header_text ||= "Create ride requester"
        @subheader_text ||= "Invite a new ride requester by email."
        @form_action ||= users_path
      else
        @submit_text ||= "Update user"
        @header_text ||= "Edit user"
        @subheader_text ||= "Update user details and roles."
        @form_action ||= user_path(id: target_user.id)
      end
    end

    def setup_input_defaults(target_user:, submitted_params:)
      @email = get_input_default(target_user:, submitted_params:, key: :email)
      @full_name = get_input_default(target_user:, submitted_params:, key: :full_name)
      @preferred_name = get_input_default(target_user:, submitted_params:, key: :preferred_name)
      @phone = get_input_default(target_user:, submitted_params:, key: :phone)
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
  end
end
