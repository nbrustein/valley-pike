# frozen_string_literal: true

module UnitsOfWork
  class UpdateProfile < UnitOfWork
  include Memery

    def initialize(user:, email:, password:, password_confirmation:)
      @user = user
      @email = email
      @password = password
      @password_confirmation = password_confirmation
      @has_email_update = email.present? && email != user.email
    end

    def execute
      password_identity = user.password_identity
      errors = ActiveModel::Errors.new(user)

      ActiveRecord::Base.transaction do
        try_to_update_user_email(errors) if has_email_update?
        if errors.empty? && (has_password_update? || has_email_update?)
          password_identity ||= user.identities.build(kind: "password")

          try_to_update_password_identity(password_identity, normalized_email || user.email, errors)
        end

        raise ActiveRecord::Rollback unless errors.empty?
      end

      Result.new(errors:)
    end

    private

    attr_reader :user, :email, :password, :password_confirmation

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
