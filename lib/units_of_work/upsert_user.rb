module UnitsOfWork
  class UpsertUser < UnitOfWork
    include Memery

    def initialize(executor_id:, params:)
      super
      @email = params.fetch(:email)
      @full_name = params.fetch(:full_name)
      @preferred_name = params.fetch(:preferred_name)
      @phone = params.fetch(:phone)
      @user_roles = params.fetch(:user_roles)
      @driver_qualifications = params.fetch(:driver_qualifications, [])
      @password = params[:password]
    end

    private

    attr_reader :email, :full_name, :preferred_name, :phone, :user_roles, :driver_qualifications, :password

    memoize def normalized_email
      Identity.normalize_email(email)
    end

    def execute_unit_of_work(errors:)
      user = User.find_by(email: normalized_email)

      if user.nil?
        delegate_work { execute_create_user_uow }
        return
      end

      delegate_work { execute_update_user_uow(user) }
    end

    def audit_params
      filtered = params.deep_dup
      filtered[:password] = "[FILTERED]" if filtered[:password].present?
      filtered
    end

    memoize def execute_create_user_uow
      UnitsOfWork::CreateUser.execute(
        executor_id:,
        params: {
          email: normalized_email,
          full_name:,
          preferred_name:,
          phone:,
          user_roles:,
          password:,
          driver_qualifications:,
        }
      )
    end

    def execute_update_user_uow(user)
      UnitsOfWork::UpdateUser.execute(
        executor_id:,
        params: {
          id: user.id,
          full_name:,
          preferred_name:,
          phone:,
          user_roles:,
          driver_qualifications:,
          password:,
        }
      )
    end
  end
end
