# frozen_string_literal: true

module IdentityConcerns
  module IsDeviseResource
    extend ActiveSupport::Concern

    class_methods do
      def find_for_database_authentication(warden_conditions)
        conditions = warden_conditions.dup
        if (email = conditions.delete(:email))
          where(conditions).find_by(email: normalize_email(email))
        else
          where(conditions).find_by(conditions)
        end
      end
    end
  end
end
