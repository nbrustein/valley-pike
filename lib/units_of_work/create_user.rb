module UnitsOfWork
  class CreateUser < UnitOfWork
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

    def execute_unit_of_work(errors:)
      user = build_user(errors)
      return if errors.any?

      save_user_with_human(user, errors)
      return if errors.any?

      create_roles(user, errors)
      return if errors.any?

      create_password_identity(user, errors) if password.present?
    end

    def audit_params
      filtered = params.deep_dup
      filtered[:password] = "[FILTERED]" if filtered[:password].present?
      filtered[:roles] = roles.map do |role, organization_id|
        {role:, organization_id:}
      end
      filtered
    end

    memoize def normalized_email
      Identity.normalize_email(email)
    end

    def build_user(errors)
      if User.exists?(email: normalized_email)
        errors.add(:email, "already exists")
        return nil
      end

      user = User.new
      user.email = normalized_email
      human = user.build_human
      human.full_name = full_name
      human.phone = phone
      human.sortable_name = sortable_name
      user
    end

    def save_user_with_human(user, errors)
      return if user.save

      merge_errors(errors, user)
    end

    def create_roles(user, errors)
      roles.uniq.each do |role, organization_id|
        user_role = user.user_roles.build(role:, organization_id:)
        next if user_role.save

        merge_errors(errors, user_role)
      end
    end

    def create_password_identity(user, errors)
      identity = Identity.new(kind: "password", email: normalized_email)
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
  end
end
