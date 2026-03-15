require "rails_helper"

RSpec.describe AdminUserMutatePolicy do
  let(:policy) { described_class.new(executor, nil) }
  let(:executor_role) { UserRole::DEVELOPER }
  let(:executor_user_role) { executor_role ? build(:user_role, role: executor_role) : nil }
  let(:executor) {
    executor = create(:user)
    if executor_user_role
      executor_user_role.user = executor
      executor_user_role.save!
    end
    executor
  }
  let(:target_user) { create(:user, role: target_user_role) }
  let(:target_user_role) { UserRole::DRIVER }

  describe "#new?" do
    context 'when there is no user on the policy' do
      let(:executor) { nil }
      it 'is false' do
        expect(policy.new?).to be(false)
      end
    end

    context 'when the executor is not allowed to create users' do
      let(:executor_role) { UserRole::DRIVER }
      it 'is false' do
        expect(policy.new?).to be(false)
      end
    end

    context 'when the executor is allowed to create users' do
      let(:executor_role) { UserRole::VANITA_ADMIN }
      it 'is true' do
        expect(policy.new?).to be(true)
      end
    end
  end

  describe "#create?" do
    let(:uow) { uow_params && executor ? UnitsOfWork::CreateUser.new(executor_id: executor.id, params: uow_params) : nil }
    let(:policy) { described_class.new(executor, uow) }
    let(:target_user_role) { nil }
    let(:default_uow_params) do
      {
        email: "new.user@example.com",
        full_name: "New User",
        preferred_name: "New",
        phone: "555-1212",
        user_roles: [],
      }
    end
    let(:uow_params) do
      {
        email: "new.user@example.com",
        full_name: "New User",
        preferred_name: "New",
        phone: "555-1212",
        user_roles: target_user_role ? [ {role: target_user_role, organization_id: nil} ] : [],
      }
    end

    context 'when there is no executor' do
      let(:executor) { nil }
      it 'is false' do
        expect(policy.create?).to be(false)
      end
    end

    context 'when the executor is not allowed to create users' do
      let(:executor_role) { UserRole::DRIVER }
      it 'is false' do
        expect(policy.create?).to be(false)
      end
    end

    context 'when the executor is allowed to create users' do
      let(:executor_role) { UserRole::VANITA_ADMIN }

      context 'when the provided role for the target user is not allowed' do
        let(:target_user_role) { UserRole::DEVELOPER }

        it 'is false' do
          expect(policy.create?).to be(false)
        end
      end

      context 'when the provided role for the target user is allowed' do
        let(:target_user_role) { UserRole::DRIVER }

        it 'is true' do
          expect(policy.create?).to be(true)
        end
      end
    end
  end

  describe "#edit?" do
    let(:policy) { described_class.new(executor, target_user) }

    context "when executor cannot new?" do
      let(:executor_role) { UserRole::DRIVER }

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
      let(:executor_role) { UserRole::VANITA_ADMIN }
      let(:target_user) { create(:user, role: UserRole::DEVELOPER) }

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

    context "when the executor cannot edit" do
      let(:executor_role) { UserRole::DRIVER }

      it "is false" do
        expect(policy.update?).to be(false)
      end
    end

    context "when user can new?" do
      context "when user cannot create given params passed to uow" do
        let(:executor_role) { UserRole::VANITA_ADMIN }
        let(:uow_user_roles) { [ {role: UserRole::DEVELOPER, organization_id: nil} ] }

        it "is false" do
          expect(policy.update?).to be(false)
        end
      end

      context "when user cannot edit given the current state of the target user" do
        let(:executor_role) { UserRole::VANITA_ADMIN }
        let(:target_user_role) { UserRole::DEVELOPER }
        let(:uow_params) { {user_roles: [ {role: UserRole::DRIVER, organization_id: nil} ], id: target_user.id} }

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
end
