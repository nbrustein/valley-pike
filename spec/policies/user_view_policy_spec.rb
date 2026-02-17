require "rails_helper"

RSpec.describe UserViewPolicy do
  let(:current_user) { create(:user) }
  let(:policy) { UserViewPolicy.new(current_user, User) }
  let(:scope) { described_class::Scope.new(current_user, User).resolve }

  describe "#index?" do
    context "when there is no current user" do
      let(:current_user) { nil }

      it "returns false" do
        expect(policy.index?).to be(false)
      end
    end

    context "when the current user has global org_admin permissions" do
      before do
        create(:user_role, user: current_user, role: UserRole::VANITA_ADMIN)
      end

      it "returns true" do
        expect(policy.index?).to be(true)
      end
    end

    context "when the current user has org-specific org_admin permissions" do
      before do
        organization = create(:organization)
        create(:user_role, user: current_user, role: UserRole::ORG_ADMIN, organization:)
      end

      it "returns true" do
        expect(policy.index?).to be(true)
      end
    end

    context "when the current user has no org_admin permissions" do
      before do
        create(:user_role, user: current_user, role: UserRole::DRIVER)
      end

      it "returns false" do
        expect(policy.index?).to be(false)
      end
    end
  end

  describe "#scope" do
    let!(:organization_1) { create(:organization) }
    let!(:ride_requester_for_org_1) do
      user = create(:user)
      create(:user_role, user: user, role: UserRole::RIDE_REQUESTER, organization: organization_1)
      user
    end

    context "when there is no current user" do
      let(:current_user) { nil }

      it "returns an empty query" do
        expect(scope).to be_empty
      end
    end

    context "when the current user has vanita_admin permissions" do
      let!(:organization_2) { create(:organization) }
      let!(:ride_requester_for_org_2) do
        user = create(:user)
        create(:user_role, user: user, role: UserRole::RIDE_REQUESTER, organization: organization_2)
        user
      end
      let!(:org_admin) do
        user = create(:user)
        create(:user_role, user: user, role: UserRole::ORG_ADMIN, organization: organization_2)
        user
      end
      before do
        create(:user_role, user: current_user, role: UserRole::VANITA_ADMIN)
      end

      it "returns all users" do
        users = scope.to_a
        expect(users).to include(
          ride_requester_for_org_1,
          ride_requester_for_org_2,
          org_admin)
      end
    end

    context "when the current user has org-specific org_admin permissions" do
      let!(:organization_2) { create(:organization) }
      let!(:ride_requester_for_org_2) do
        user = create(:user)
        create(:user_role, user: user, role: UserRole::RIDE_REQUESTER, organization: organization_2)
        user
      end

      before do
        create(:user_role, user: current_user, role: UserRole::ORG_ADMIN, organization: organization_1)
      end

      it "returns ride requesters for the current user's organization" do
        users = scope.to_a
        expect(users).to include(ride_requester_for_org_1)
        expect(users).not_to include(ride_requester_for_org_2)
      end
    end

    context "when the current user has no org_admin permissions" do
      before do
        create(:user_role, user: current_user, role: UserRole::DRIVER)
      end

      it "returns an empty query" do
        expect(scope).to be_empty
      end
    end
  end
end
