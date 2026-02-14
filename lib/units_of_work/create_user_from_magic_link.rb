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
        user = User.find_by(email: identity.email)
        if user.nil?
          create_user_result = UnitsOfWork::CreateUser.execute(
            email: identity.email,
            full_name: identity.email,
            phone: nil,
            sortable_name: identity.email,
            roles: []
          )

          merge_errors(errors, create_user_result.errors)
          raise ActiveRecord::Rollback if errors.any?

          user = User.find_by!(email: identity.email)
        end

        # update_columns because this runs in Warden::Manager.after_set_user, and we don't want to
        # trigger validations or callbacks during the login hook. update_columns bypasses
        # validations, callbacks, and timestamps, so it won't fail due to unrelated validation rules.
        identity.update_columns(user_id: user.id)
      end

      Result.new(errors:)
    end

    private

    def merge_errors(target_errors, source_errors)
      source_errors.each do |error|
        target_errors.add(error.attribute, error.message)
      end
    end
  end
end
