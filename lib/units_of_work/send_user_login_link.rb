module UnitsOfWork
  class SendUserLoginLink < UnitOfWork
    include Memery

    def initialize(executor_id:, params:)
      super
      @user_id = params.fetch(:user_id)
    end

    private

    attr_reader :user_id

    memoize def user
      User.find_by(id: user_id)
    end

    def execute_unit_of_work(errors:)
      if user.nil?
        errors.add(:base, "User not found")
        return
      end

      identity = Identity.find_or_create_magic_link_identity_for_user!(user)
      unless identity.active_for_magic_link_authentication?
        errors.add(:base, "User is disabled")
        return
      end

      identity.send_magic_link
    end
  end
end
