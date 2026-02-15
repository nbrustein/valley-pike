module UnitsOfWork
  class UpdateProfile < UnitOfWork
    include Memery

    def initialize(executor_id:, params:)
      super
      @email = params[:email]
      @password = params[:password]
      @password_confirmation = params[:password_confirmation]
      @user_id = params.fetch(:user_id)
      @has_email_update = email.present? && email != user.email
    end

    private

    attr_reader :email, :password, :password_confirmation

    memoize def user
      User.find(@user_id)
    end

    def execute_unit_of_work(errors:)
      password_identity = user.password_identity

      try_to_update_user_email(errors) if has_email_update?
      if errors.empty? && (has_password_update? || has_email_update?)
        password_identity ||= user.identities.build(kind: "password")

        try_to_update_password_identity(password_identity, normalized_email || user.email, errors)
      end
    end

    def audit_params
      _ = params.clone
      _[:password] = "[FILTERED]" if _[:password].present?
      _[:password_confirmation] = "[FILTERED]" if _[:password_confirmation].present?
      _
    end

    def has_password_update?
      password.present? || password_confirmation.present?
    end

    def has_email_update?
      @has_email_update == true
    end

    def try_to_update_user_email(errors)
      return if normalized_email.blank?

      return if user.update(email: normalized_email)

      merge_errors(errors, user)
    end

    def try_to_update_password_identity(identity, email, errors)
      identity.email = email
      identity.password = password
      identity.password_confirmation = password_confirmation
      identity.save
      merge_errors(errors, identity)
    end

    memoize def normalized_email
      normalized = Identity.normalize_email(email)
      normalized.presence
    end

    def merge_errors(errors, record)
      record.errors.each do |error|
        errors.add(error.attribute, error.message)
      end
    end
  end
end
