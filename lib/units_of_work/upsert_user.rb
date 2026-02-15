module UnitsOfWork
  class UpsertUser < UnitOfWork
    include Memery

    def initialize(executor_id:, params:)
      super
      @email = params.fetch(:email)
      @full_name = params.fetch(:full_name)
      @phone = params.fetch(:phone)
      @sortable_name = params.fetch(:sortable_name)
      @roles = normalize_roles(params.fetch(:roles))
      @password = params[:password]
    end

    private

    attr_reader :email, :full_name, :phone, :sortable_name, :roles, :password

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

      upsert_password_identity(user, errors) if password.present?
    end

    def audit_params
      filtered = params.deep_dup
      filtered[:password] = "[FILTERED]" if filtered[:password].present?
      filtered[:roles] = roles.map do |role, organization_id|
        {role:, organization_id:}
      end
      filtered
    end

    memoize def create_user_result
      UnitsOfWork::CreateUser.execute(
        executor_id:,
        params: {
          email: normalized_email,
          full_name:,
          phone:,
          sortable_name:,
          roles: roles.map {|role, organization_id| {role:, organization_id:} },
          password:
        }
      )
    end

    def upsert_human(user, errors)
      human = user.human || user.build_human
      human.full_name = full_name
      human.phone = phone
      human.sortable_name = sortable_name
      return if human.save

      merge_errors(errors, human)
    end

    def sync_roles(user, errors)
      desired_pairs = roles.uniq

      user.user_roles.find_each do |user_role|
        next if desired_pairs.include?([ user_role.role, user_role.organization_id ])

        user_role.destroy!
      end

      desired_pairs.each do |role, organization_id|
        user_role = user.user_roles.find_or_initialize_by(role:, organization_id:)
        next if user_role.persisted?
        next if user_role.save

        merge_errors(errors, user_role)
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

    def normalize_roles(role_params)
      role_params.map do |entry|
        if entry.is_a?(Hash)
          [ entry.fetch(:role), entry[:organization_id] ]
        else
          role, organization = entry
          [ role, organization&.id ]
        end
      end
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
