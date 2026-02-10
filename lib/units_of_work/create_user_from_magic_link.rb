# frozen_string_literal: true

module UnitsOfWork
    class CreateUserFromMagicLink < UnitOfWork
      include Memery

      attr_reader :identity

      def initialize(identity:)
        @identity = identity
      end

      def execute
        errors = ActiveModel::Errors.new(identity)

        ActiveRecord::Base.transaction do
            user = User.find_or_create_by!(email: identity.email)

            # update_columns because this runs in Warden::Manager.after_set_user, and we don’t want to
            # trigger validations or callbacks during the login hook. update_columns bypasses
            # validations, callbacks, and timestamps, so it won’t fail due to unrelated validation rules (and it keeps the login flow from blowing up). Using update! here
            # would run validations and could raise, which would interrupt the sign‑in process.
            identity.update_columns(user_id: user.id)
        end

        Result.new(errors:)
      end
    end
end
