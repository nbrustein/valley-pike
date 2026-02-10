# frozen_string_literal: true

module IdentityConcerns
  module SupportsMagicLinks
    extend ActiveSupport::Concern

    included do
      devise :magic_link_authenticatable, :rememberable
    end

    class_methods do
      def find_or_create_magic_link_identity!(email)
        normalized_email = normalize_email(email)
        identity = find_by(kind: "magic_link", email: normalized_email)
        return identity if identity

        transaction do
          user = User.create!
          create!(user:, kind: "magic_link", email: normalized_email)
        end
      rescue ActiveRecord::RecordNotUnique
        find_by!(kind: "magic_link", email: normalized_email)
      end
    end

    def magic_link_url(host:, expires_at: 2.hours.from_now, remember_me: true, protocol: nil)
      token = encode_passwordless_token(expires_at:)
      options = {
        identity: {
          email:,
          token:,
          remember_me:
        },
        host:
      }
      options[:protocol] = protocol if protocol

      Rails.application.routes.url_helpers.identity_magic_link_url(**options)
    end
  end
end
