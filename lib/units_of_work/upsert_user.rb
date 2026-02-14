module UnitsOfWork
  class UpsertUser < UnitOfWork
    include Memery

    def initialize(email:, full_name:, phone:, sortable_name:, roles:, password: nil)
      @email = email
      @full_name = full_name
      @phone = phone
      @sortable_name = sortable_name
      @roles = roles
      @password = password
    end

    def execute
      user = User.find_by(email: normalized_email)
      return create_user_result if user.nil?

      errors = ActiveModel::Errors.new(user)

      ActiveRecord::Base.transaction do
        upsert_human(user, errors)
        raise ActiveRecord::Rollback if errors.any?

        sync_roles(user, errors)
        raise ActiveRecord::Rollback if errors.any?

        upsert_password_identity(user, errors) if password.present?
        raise ActiveRecord::Rollback if errors.any?
      end

      Result.new(errors:)
    end

    private

    attr_reader :email, :full_name, :phone, :sortable_name, :roles, :password

    memoize def normalized_email
      Identity.normalize_email(email)
    end

    memoize def create_user_result
      UnitsOfWork::CreateUser.execute(
        email: normalized_email,
        full_name:,
        phone:,
        sortable_name:,
        roles:,
        password:
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
      desired_pairs = roles.map {|role, organization| [ role, organization&.id ] }

      user.user_roles.find_each do |user_role|
        next if desired_pairs.include?([ user_role.role, user_role.organization_id ])

        user_role.destroy!
      end

      roles.each do |role, organization|
        user_role = user.user_roles.find_or_initialize_by(role:, organization:)
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

    def merge_errors(errors, record)
      record.errors.each do |error|
        errors.add(error.attribute, error.message)
      end
    end
  end
end
