module IdentityConcerns
  module HasEmail
    extend ActiveSupport::Concern

    EMAIL_BASED_KINDS = %w[magic_link password].freeze

    included do
      # We cannot use Devise :validatable, because it enforces global email uniqueness,
      # which prevents having a password identity and a magic link identity on the same
      # user. This scoped check replaces the following from Devise :validatable:
      #
      # - validates_presence_of :email (if email_required?, which defaults to true)
      # - validates_uniqueness_of :email (unscoped, case_sensitive, on email change)
      # - validates_format_of :email (using Devise.email_regexp, on email change)
      #
      # Sources:
      # - https://github.com/heartcombo/devise/issues/4767
      # - https://jessewolgamott.com/blog/2011/12/08/the-one-where-devise-validations-are-customized/
      validates :email,
        presence: true,
        format: {with: Devise.email_regexp},
        uniqueness: {scope: :kind},
        if: -> { email_based? && will_save_change_to_email? }
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
