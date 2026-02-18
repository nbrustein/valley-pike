class UsersMutateController < ApplicationController
    include Memery

    def new
      authorize(nil, :new?, policy_class: UserMutatePolicy)
      @user = User.new
      load_form_organizations
      render :mutate
    end

    def create
      uow = UnitsOfWork::CreateUser.new(
        executor_id: current_user.id,
        params: create_user_params
      )
      authorize(uow, :create?, policy_class: UserMutatePolicy)
      result = uow.execute
      if result.success?
        redirect_to users_path, notice: "User created."
      else
        @errors = result.errors
        render :mutate, status: :unprocessable_entity
      end
    end

    private

    def load_form_organizations
      @organizations = UserMutatePolicy::OrganizationScope.new(current_user, nil).resolve.order(:name)
      @default_organization_id = @organizations.size == 1 ? @organizations.first.id : nil
    end

    def create_user_params
      params.require(:user).permit(:email, :organization_id, :user_roles)
    end
end
