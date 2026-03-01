require "rails_helper"

RSpec.describe UserMutatePolicy do
  let(:policy) { described_class.new(executor, nil) }
  let(:executor_role) { nil }
  let(:executor) {
    executor = create(:user)
    if executor_role
      executor_role.user = executor
      executor_role.save!
    end
    executor
  }
  let(:target_user) { 
    user = create(:user) 
    create(:user_role, user:, role: UserRole::DRIVER)
    user
  }

  describe "#new?" do
    context 'when there is no user on the policy' do
      let(:executor) { nil }
      it 'is false' do
        expect(policy.new?).to be(false)
      end
    end

    context 'when the policy user is not an org admin' do
      let(:executor_role) { build(:user_role, role: UserRole::DRIVER) }
      it 'is false' do
        expect(policy.new?).to be(false)
      end
    end

    context 'when the policy user is an org admin' do
      let(:executor_role) { build(:user_role, role: UserRole::VANITA_ADMIN) }
      it 'is true' do
        expect(policy.new?).to be(true)
      end
    end
  end

  describe "#create?" do
    let(:uow) { uow_params ? UnitsOfWork::CreateUser.new(executor_id: executor.id, params: uow_params) : nil }
    let(:policy) { described_class.new(executor, uow) }
    let(:default_uow_params) do
      {
        email: "new.user@example.com",
        full_name: "New User",
        preferred_name: "New",
        phone: "555-1212",
        user_roles: [],
      }
    end
    let(:uow_params) { nil }
    let(:executor_role) { build(:user_role, role: UserRole::VANITA_ADMIN) }

    context 'when there is no user on the policy' do
      let(:executor) { nil }
      it 'is false' do
        expect(policy.create?).to be(false)
      end
    end

    context 'when the policy user is not an org admin' do
      let(:executor_role) { build(:user_role, role: UserRole::DRIVER) }
      it 'is false' do
        expect(policy.create?).to be(false)
      end
    end

    context 'when a user_role has a disallowed role' do
      # ORG_ADMINs are not allowed to create DRIVERs
      let(:uow_params) { default_uow_params.merge({user_roles: [ {role: UserRole::DRIVER, organization_id: nil} ]}) }
      let(:executor_role) { build(:user_role, role: UserRole::ORG_ADMIN, organization: create(:organization)) }

      it 'is false' do
        expect(policy.create?).to be(false)
      end
    end

    context 'when a user_role has a disallowed organization' do
      let(:organization_1) { create(:organization) }
      let(:organization_2) { create(:organization) }
      let(:uow_params) { default_uow_params.merge({user_roles: [ {role: UserRole::RIDE_REQUESTER, organization_id: organization_1.id} ]}) }
      let(:executor_role) { build(:user_role, role: UserRole::ORG_ADMIN, organization: organization_2) }

      it 'is false' do
        expect(policy.create?).to be(false)
      end
    end

    context 'when the executor creates a user with allowed roles' do
      let(:organization) { create(:organization) }
      let(:uow_params) { default_uow_params.merge({user_roles: [ {role: UserRole::RIDE_REQUESTER, organization_id: organization.id} ]}) }
      let(:executor_role) { build(:user_role, role: UserRole::ORG_ADMIN, organization:) }

      it 'is true' do
        expect(policy.create?).to be(true)
      end
    end

    context 'when the executor has vanita_admin permissions' do
      let(:uow_params) { default_uow_params.merge({user_roles: [ {role: UserRole::DRIVER} ]}) }
      let(:executor_role) { build(:user_role, role: UserRole::VANITA_ADMIN) }

      it 'is true' do
        expect(policy.create?).to be(true)
      end
    end
  end

  describe "#edit?" do
    let(:policy) { described_class.new(executor, target_user) }
    let(:executor_role) { build(:user_role, role: UserRole::VANITA_ADMIN) }

    context "when executor cannot new?" do
      let(:executor_role) { build(:user_role, role: UserRole::DRIVER) }

      it "is false" do
        expect(policy.edit?).to be(false)
      end
    end

    context "when there is no target user" do
      let(:target_user) { nil }

      it "is false" do
        expect(policy.edit?).to be(false)
      end
    end

    context "when the executor cannot create a user with target user's user_roles" do
      # org_admin is not allowed to create DRIVERs
      let(:executor_role) { build(:user_role, role: UserRole::ORG_ADMIN, organization: create(:organization)) }

      it "is false" do
        expect(policy.edit?).to be(false)
      end
    end

    context "when the user can create a user with the target user's user roles" do
      it "is true" do
        expect(policy.edit?).to be(true)
      end
    end
  end
  
  describe "#update?" do
    let(:uow_user_roles) { [ {role: UserRole::DRIVER, organization_id: nil} ] }
    let(:uow) { UnitsOfWork::UpdateUser.new(executor_id: executor.id, params: uow_params) }
    let(:uow_params) { {user_roles: uow_user_roles, id: target_user.id} }
    let(:policy) { described_class.new(executor, uow) }
    let(:executor_role) { build(:user_role, role: UserRole::VANITA_ADMIN) }

    context "when user cannot edit target user" do
      let(:executor_role) { build(:user_role, role: UserRole::DRIVER) }

      it "is false" do
        expect(policy.update?).to be(false)
      end
    end

    context "when user cannot create given params passed to uow" do
      let(:uow_user_roles) { [ {role: UserRole::VANITA_ADMIN, organization_id: nil} ] }

      it "is false" do
        expect(policy.update?).to be(false)
      end
    end

    context "when user can edit and create" do
      it "is true" do
        expect(policy.update?).to be(true)
      end
    end


  end
end
