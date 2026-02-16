require "rails_helper"

RSpec.describe UsersHelper do
  let(:current_user) { build(:user) }
  let(:policy) { instance_double(UserPolicy) }
  let(:scope_instance) { instance_double(UserPolicy::Scope) }

  before do
    allow(UserPolicy::Scope).to receive(:new).with(current_user, User).and_return(scope_instance)
    allow(helper).to receive(:view_users_policy).and_return(policy)
    user = current_user
    helper.define_singleton_method(:current_user) { user }
    helper.clear_memery_cache!
  end

  describe "#show_users_index_link?" do
    context "when the policy scope has results" do
      before do
        allow(scope_instance).to receive(:resolve)
          .and_return(instance_double("Relation", exists?: true))
      end

      it "returns true" do
        expect(helper.show_users_index_link?).to be(true)
      end
    end

    context "when the policy scope has no results" do
      before do
        allow(scope_instance).to receive(:resolve)
          .and_return(instance_double("Relation", exists?: false))
      end

      it "returns false" do
        expect(helper.show_users_index_link?).to be(false)
      end
    end
  end

  describe "#users_index_label" do
    let(:has_org_admin_permissions_for_all_organizations) { false }
    before do
      expect(policy).to receive(:has_org_admin_permissions_for_all_organizations?).and_return(has_org_admin_permissions_for_all_organizations)
    end

    context "when the user has org admin permissions for all organizations" do
      let(:has_org_admin_permissions_for_all_organizations) { true }

      it "returns Users" do
        expect(helper.users_index_label).to eq("Users")
      end
    end

    context "when there are multiple organizations" do
      before do
        allow(policy).to receive(:roles_granting_org_admin_permissions)
          .and_return([
            instance_double(UserRole, organization: instance_double(Organization, abbreviation: "UDO")),
            instance_double(UserRole, organization: instance_double(Organization, abbreviation: "VDO"))
          ])
      end

      it "returns Users" do
        expect(helper.users_index_label).to eq("Users")
      end
    end

    context "when there are no organizations" do
      before do
        allow(policy).to receive(:roles_granting_org_admin_permissions).and_return([])
      end

      it "returns nil" do
        expect(helper.users_index_label).to be_nil
      end
    end

    context "when there is one organization" do
      before do
        allow(policy).to receive(:roles_granting_org_admin_permissions)
          .and_return([
            instance_double(UserRole, organization: instance_double(Organization, abbreviation: "UDO"))
          ])
      end

      it "returns the organization label" do
        expect(helper.users_index_label).to eq("UDO Users")
      end
    end
  end
end
