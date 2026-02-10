# frozen_string_literal: true

module IdentityConcerns
  module HasEmail
    extend ActiveSupport::Concern

    EMAIL_BASED_KINDS = %w[magic_link password].freeze

    included do
      validates :email, presence: true, if: :email_based?
      validates :email, uniqueness: { scope: :kind }, if: :email_based?
    end

    class_methods do
      def normalize_email(value)
        value.to_s.strip.downcase
      end
    end

    def email=(value)
      super(self.class.normalize_email(value))
    end

    def email_based?
      kind.in?(EMAIL_BASED_KINDS)
    end
  end
end
