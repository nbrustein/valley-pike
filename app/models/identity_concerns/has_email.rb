module IdentityConcerns
  module HasEmail
    extend ActiveSupport::Concern

    EMAIL_BASED_KINDS = %w[magic_link password].freeze

    included do
      validates :email, uniqueness: {scope: :kind}, if: :password_identity?
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

    def password_identity?
      kind == "password"
    end
  end
end
