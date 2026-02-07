# frozen_string_literal: true

module IdentityConcerns
  module HasEmail
    extend ActiveSupport::Concern

    EMAIL_BASED_KINDS = %w[magic_link password].freeze

    included do
      validates :email_normalized, presence: true, if: :email_based?
      validates :email_normalized, uniqueness: { scope: :kind }, if: :email_based?
    end

    class_methods do
      def normalize_email(value)
        value.to_s.strip.downcase
      end
    end

    def email
      email_normalized
    end

    def email=(value)
      self.email_normalized = self.class.normalize_email(value)
    end

    def email_based?
      kind.in?(EMAIL_BASED_KINDS)
    end
  end
end
