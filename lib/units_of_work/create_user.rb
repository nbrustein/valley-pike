module UnitsOfWork
  class CreateUser < UnitOfWork
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
      errors = ActiveModel::Errors.new(User.new)
      user = nil

      ActiveRecord::Base.transaction do
        user = build_user(errors)
        raise ActiveRecord::Rollback if errors.any?

        save_user_with_human(user, errors)
        raise ActiveRecord::Rollback if errors.any?

        create_roles(user, errors)
        raise ActiveRecord::Rollback if errors.any?

        create_password_identity(user, errors) if password.present?
        raise ActiveRecord::Rollback if errors.any?
      end

      Result.new(errors:)
    end

    private

    attr_reader :email, :full_name, :phone, :sortable_name, :roles, :password

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
      roles.uniq.each do |role, organization|
        user_role = user.user_roles.build(role:, organization:)
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

    def merge_errors(errors, record)
      record.errors.each do |error|
        errors.add(error.attribute, error.message)
      end
    end
  end
end
