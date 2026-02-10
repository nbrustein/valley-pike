# frozen_string_literal: true

module IdentityConcerns
  module SupportsPasswordAuthentication
    extend ActiveSupport::Concern

    included do
      devise :database_authenticatable, :validatable

      attr_accessor :skip_password_validation
      attr_accessor :skip_password_strength_validation

      validate :password_strength, if: :password_strength_required?

      validate :password_length, if: :password_length_required?
    end

    protected

    def password_required?
      return false if skip_password_validation

      kind == "password" && super
    end

    private

    def password_length_required?
      return false if skip_password_validation

      kind == "password" && password.present?
    end

    def password_length
      return if password.length.between?(12, 128)

      errors.add(:password, "is too short (minimum is 12 characters)")
    end

    def password_strength_required?
      kind == "password" &&
        !skip_password_validation &&
        !skip_password_strength_validation &&
        password.present?
    end

    def password_strength
      return if password.length >= 12 &&
        password.match?(/[a-z]/) &&
        password.match?(/[A-Z]/) &&
        password.match?(/\d/) &&
        password.match?(/[^A-Za-z0-9]/)

      errors.add(
        :password,
        "must be at least 12 characters and include upper, lower, number, and symbol"
      )
    end
  end
end
