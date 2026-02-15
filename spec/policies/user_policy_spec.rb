require "rails_helper"

RSpec.describe UserPolicy do
  describe "Scope#resolve" do
    let(:organization) { create(:organization, abbreviation: "UDO") }
    let(:other_organization) { create(:organization, abbreviation: "VDO") }

    let!(:udo_requester) { create(:user, human: build(:human, full_name: "UDO Requester", sortable_name: "Requester")) }
    let!(:vdo_requester) { create(:user, human: build(:human, full_name: "VDO Requester", sortable_name: "Requester")) }
    let!(:udo_admin) { create(:user, human: build(:human, full_name: "UDO Admin", sortable_name: "Admin")) }

    before do
      create(:user_role, user: udo_requester, role: UserRole::RIDE_REQUESTER, organization:)
      create(:user_role, user: vdo_requester, role: UserRole::RIDE_REQUESTER, organization: other_organization)
      create(:user_role, user: udo_admin, role: UserRole::ORG_ADMIN, organization:)
    end

    context "when the current user has organization-scoped org_admin permissions" do
      let(:current_user) { create(:user) }

      before do
        create(:user_role, user: current_user, role: UserRole::ORG_ADMIN, organization:)
      end

      it "returns ride requesters in the allowed organizations" do
        resolved = described_class::Scope.new(current_user, User).resolve
        expect(resolved).to contain_exactly(udo_requester)
      end
    end

    context "when the current user has global org_admin permissions" do
      let(:current_user) { create(:user) }

      before do
        create(:user_role, user: current_user, role: UserRole::VANITA_ADMIN)
      end

      it "returns all users with humans" do
        resolved = described_class::Scope.new(current_user, User).resolve
        expect(resolved).to include(udo_requester, vdo_requester, udo_admin)
      end
    end

    context "when the current user does not have org admin permissions" do
      let(:current_user) { create(:user) }

      before do
        create(:user_role, user: current_user, role: UserRole::RIDE_REQUESTER, organization:)
      end

      it "returns none" do
        resolved = described_class::Scope.new(current_user, User).resolve
        expect(resolved).to be_empty
      end
    end
  end
end
