module UnitsOfWork
  class UpdateUser < UnitOfWork
    include Memery

    attr_reader :user_id, :user_roles, :driver_qualifications, :full_name, :preferred_name, :phone, :password, :disabled
    attr_reader :has_full_name_key, :has_preferred_name_key, :has_phone_key,
                :has_user_roles_key, :has_driver_qualifications_key, :has_password_key, :has_disabled_key

    def initialize(executor_id:, params:)
      super
      @user_id = params.fetch(:id)
      @full_name = params[:full_name]
      @preferred_name = params[:preferred_name]
      @phone = params[:phone]
      @user_roles = params[:user_roles]
      @driver_qualifications = params[:driver_qualifications]
      @password = params[:password]
      @disabled = params[:disabled]
      @has_full_name_key = params.key?(:full_name)
      @has_preferred_name_key = params.key?(:preferred_name)
      @has_phone_key = params.key?(:phone)
      @has_user_roles_key = params.key?(:user_roles)
      @has_driver_qualifications_key = params.key?(:driver_qualifications)
      @has_password_key = params.key?(:password)
      @has_disabled_key = params.key?(:disabled)
    end

    memoize def user
      User.find_by(id: user_id)
    end

    private

    attr_reader :user_id, :driver_qualifications, :full_name, :preferred_name, :phone, :password, :disabled
    attr_reader :has_full_name_key, :has_preferred_name_key, :has_phone_key,
                :has_user_roles_key, :has_driver_qualifications_key, :has_password_key, :has_disabled_key

    def execute_unit_of_work(errors:)
      user = self.user
      if user.nil?
        errors.add(:base, "User not found")
        return
      end

      update_human(user, errors)
      return if errors.any?

      update_user_record(user, errors)
      return if errors.any?

      validate_ride_requests(user, errors)
      return if errors.any?

      sync_roles(user, errors)
      return if errors.any?

      sync_driver_qualifications(user, errors)
      return if errors.any?

      upsert_password_identity(user, errors) if password.present?
    end

    def audit_params
      filtered = params.deep_dup
      filtered[:password] = "[FILTERED]" if filtered[:password].present?
      filtered
    end

    def update_human(user, errors)
      return unless has_full_name_key || has_preferred_name_key || has_phone_key

      human = user.human || user.build_human
      human.full_name = full_name if has_full_name_key
      human.preferred_name = preferred_name if has_preferred_name_key
      human.phone = phone if has_phone_key
      return if human.save

      merge_errors(errors, human)
    end

    def update_user_record(user, errors)
      return unless has_disabled_key

      user.disabled = disabled
      return if user.save

      merge_errors(errors, user)
    end

    def validate_ride_requests(user, errors)
      removed_roles = if has_user_roles_key
        user.user_roles.reject {|ur| user_roles.include?(role: ur.role, organization_id: ur.organization_id) }
      else
        []
      end

      removed_qualifications = if has_driver_qualifications_key
        user.driver_qualifications.reject {|dq| driver_qualifications.include?(dq.qualification) }
      else
        []
      end

      validator = RideRequestAssignmentValidator.new(
        removed_user_roles: removed_roles,
        removed_driver_qualifications: removed_qualifications
      )
      return if validator.validate

      validator.errors.each {|e| errors.add(e.attribute, e.message) }
    end

    def sync_roles(user, errors)
      return unless has_user_roles_key

      user.user_roles.find_each do |user_role|
        next if user_roles.include?(role: user_role.role, organization_id: user_role.organization_id)

        user_role.destroy!
      end

      user_roles.each do |role_attrs|
        user_role = user.user_roles.find_or_initialize_by(role_attrs)
        next if user_role.persisted?
        next if user_role.save

        merge_errors(errors, user_role)
      end
    end

    def sync_driver_qualifications(user, errors)
      return unless has_driver_qualifications_key

      user.driver_qualifications.find_each do |driver_qualification|
        next if driver_qualifications.include?(driver_qualification.qualification)

        driver_qualification.destroy!
      end

      driver_qualifications.each do |qualification|
        driver_qualification = user.driver_qualifications.find_or_initialize_by(qualification:)
        next if driver_qualification.persisted?
        next if driver_qualification.save

        merge_errors(errors, driver_qualification)
      end
    end

    def upsert_password_identity(user, errors)
      return unless has_password_key
      return if password.blank?

      identity = Identity.find_or_initialize_by(kind: "password", email: user.email)
      identity.user = user
      identity.password = password
      identity.password_confirmation = password
      identity.skip_password_validation = true
      identity.skip_password_strength_validation = true
      return if identity.save

      merge_errors(errors, identity)
    end

    def merge_errors(errors, record)
      record.errors.each do |error|
        errors.add(error.attribute, error.message)
      end
    end
  end
end
