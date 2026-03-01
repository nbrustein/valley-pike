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
        merge_errors_from_result(errors, create_user_result)
        return
      end

      merge_errors_from_result(errors, update_user_result(user))
    end

    def audit_params
      filtered = params.deep_dup
      filtered[:password] = "[FILTERED]" if filtered[:password].present?
      filtered
    end

    memoize def create_user_result
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

    def update_user_result(user)
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

    def merge_errors_from_result(errors, result)
      result.errors.each do |error|
        errors.add(error.attribute, error.message)
      end
    end
  end
end
