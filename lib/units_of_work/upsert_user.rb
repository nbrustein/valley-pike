module UnitsOfWork
  class UpsertUser < UnitOfWork
    include Memery

    def initialize(executor_id:, params:)
      super
      @email = params.fetch(:email)
      @full_name = params.fetch(:full_name)
      @preferred_name = params.fetch(:preferred_name)
      @phone = params.fetch(:phone)
      @user_roles = params.fetch(:user_roles)
      @driver_qualifications = params.fetch(:driver_qualifications, [])
      @password = params[:password]
    end

    private

    attr_reader :email, :full_name, :preferred_name, :phone, :user_roles, :driver_qualifications, :password

    memoize def normalized_email
      Identity.normalize_email(email)
    end

    def execute_unit_of_work(errors:)
      user = User.find_by(email: normalized_email)

      if user.nil?
        merge_errors_from_result(errors, create_user_result)
        return
      end

      upsert_human(user, errors)
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

    memoize def create_user_result
      UnitsOfWork::CreateUser.execute(
        executor_id:,
        params: {
          email: normalized_email,
          full_name:,
          preferred_name:,
          phone:,
          user_roles:,
          password:,
          driver_qualifications:,
        }
      )
    end

    def upsert_human(user, errors)
      human = user.human || user.build_human
      human.full_name = full_name
      human.preferred_name = preferred_name
      human.phone = phone
      return if human.save

      merge_errors(errors, human)
    end

    def sync_roles(user, errors)
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
      identity = Identity.find_or_initialize_by(kind: "password", email: normalized_email)
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

    def merge_errors_from_result(errors, result)
      result.errors.each do |error|
        errors.add(error.attribute, error.message)
      end
    end
  end
end
