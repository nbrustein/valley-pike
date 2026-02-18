require "rails_helper"

RSpec.describe UserPolicy do
  describe "#create?" do
    let(:organization) { create(:organization) }
    let(:record) { build(:user) }

    def act
      described_class.new(current_user, record).create?
    end

    def build_roles(*entries)
      entries.each do |entry|
        record.user_roles.build(**entry)
      end
    end

    context "when the record is the User class" do
      let(:record) { User }

      context "when the current user is an org admin" do
        let(:current_user) { create(:user) }

        before do
          create(:user_role, user: current_user, role: UserRole::ORG_ADMIN, organization:)
        end

        it "allows creation" do
          expect(act).to be(true)
        end
      end

      context "when the current user is not an org admin" do
        let(:current_user) { create(:user) }

        before do
          create(:user_role, user: current_user, role: UserRole::RIDE_REQUESTER, organization:)
        end

        it "denies creation" do
          expect(act).to be(false)
        end
      end
    end

    context "when the record is a user instance" do
      context "when the current user is an org admin for a specific organization" do
        let(:current_user) { create(:user) }

        before do
          create(:user_role, user: current_user, role: UserRole::ORG_ADMIN, organization:)
          build_roles(role: UserRole::RIDE_REQUESTER, organization_id: organization.id)
        end

        it "allows creation" do
          expect(act).to be(true)
        end
      end

      context "when the current user is a vanita admin" do
        let(:current_user) { create(:user) }
        let(:other_organization) { create(:organization) }

        before do
          create(:user_role, user: current_user, role: UserRole::VANITA_ADMIN)
          build_roles(role: UserRole::RIDE_REQUESTER, organization_id: other_organization.id)
        end

        it "allows creation" do
          expect(act).to be(true)
        end
      end

      context "when the record has no roles" do
        let(:current_user) { create(:user) }

        before do
          create(:user_role, user: current_user, role: UserRole::ORG_ADMIN, organization:)
        end

        it "denies creation" do
          expect(act).to be(false)
        end
      end

      context "when the record has multiple roles" do
        let(:current_user) { create(:user) }

        before do
          create(:user_role, user: current_user, role: UserRole::ORG_ADMIN, organization:)
          build_roles(
            {role: UserRole::RIDE_REQUESTER, organization_id: organization.id},
            {role: UserRole::DRIVER, organization_id: organization.id}
          )
        end

        it "denies creation" do
          expect(act).to be(false)
        end
      end

      context "when the record role is not ride requester" do
        let(:current_user) { create(:user) }

        before do
          create(:user_role, user: current_user, role: UserRole::ORG_ADMIN, organization:)
          build_roles(role: UserRole::DRIVER, organization_id: organization.id)
        end

        it "denies creation" do
          expect(act).to be(false)
        end
      end

      context "when the record organization is missing" do
        let(:current_user) { create(:user) }

        before do
          create(:user_role, user: current_user, role: UserRole::ORG_ADMIN, organization:)
          build_roles(role: UserRole::RIDE_REQUESTER, organization_id: nil)
        end

        it "denies creation" do
          expect(act).to be(false)
        end
      end

      context "when the record organization is not permitted" do
        let(:current_user) { create(:user) }
        let(:other_organization) { create(:organization) }

        before do
          create(:user_role, user: current_user, role: UserRole::ORG_ADMIN, organization:)
          build_roles(role: UserRole::RIDE_REQUESTER, organization_id: other_organization.id)
        end

        it "denies creation" do
          expect(act).to be(false)
        end
      end

      context "when there is no current user" do
        let(:current_user) { nil }

        before do
          build_roles(role: UserRole::RIDE_REQUESTER, organization_id: organization.id)
        end

        it "denies creation" do
          expect(act).to be(false)
        end
      end
    end
  end

  describe "#permitted_org_ids_for_role_management" do
    let!(:organization) { create(:organization, name: "Alpha") }
    let!(:other_organization) { create(:organization, name: "Beta") }

    context "when the current user can create ride requesters for any organization" do
      let(:current_user) { create(:user) }

      before do
        create(:user_role, user: current_user, role: UserRole::VANITA_ADMIN)
      end

      it "returns all organization ids" do
        policy = described_class.new(current_user, nil)
        expect(policy.permitted_org_ids_for_role_management).to match_array([
          organization.id,
          other_organization.id,
        ])
      end
    end

    context "when the current user is scoped to a single organization" do
      let(:current_user) { create(:user) }

      before do
        create(:user_role, user: current_user, role: UserRole::ORG_ADMIN, organization:)
      end

      it "returns the organization id" do
        policy = described_class.new(current_user, nil)
        expect(policy.permitted_org_ids_for_role_management).to eq([ organization.id ])
      end
    end
  end

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
