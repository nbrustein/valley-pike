# frozen_string_literal: true

module UserConcerns
  module HasEmail
    extend ActiveSupport::Concern

    class_methods do
      def find_by_email(email)
        find_by(email: Identity.normalize_email(email))
      end
    end
  end
end
