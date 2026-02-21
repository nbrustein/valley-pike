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
        phone: "555-1212",
        sortable_name: "User",
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
      let(:organization) { create(:organization) }

      # ORG_ADMINs are not allowed to create DRIVERs
      let(:uow_params) { default_uow_params.merge({user_roles: [ {role: UserRole::DRIVER, organization_id: organization.id} ]}) }
      let(:executor_role) { build(:user_role, role: UserRole::ORG_ADMIN, organization:) }

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
end
