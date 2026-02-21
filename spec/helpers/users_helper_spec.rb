require "rails_helper"

RSpec.describe UsersHelper do
  let(:current_user) { build(:user) }
  let(:policy) { instance_double(UserViewPolicy) }
  let(:scope_instance) { instance_double(UserViewPolicy::Scope) }

  before do
    allow(UserViewPolicy::Scope).to receive(:new).with(current_user, nil).and_return(scope_instance)
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
    let(:organizations) do
      1.upto(organization_count).map {|i| instance_double(Organization, abbreviation: "DO#{i}") }
    end
    let(:organization_ids_with_org_admin_permissions) do
      1.upto(organization_count).map {|i| i }
    end
    before do
      allow(policy).to receive(:organization_ids_with_org_admin_permissions).and_return(organization_ids_with_org_admin_permissions)
      allow(Organization).to receive(:where).with(id: organization_ids_with_org_admin_permissions).and_return(organizations)
    end

    context "when there are multiple organizations" do
      let(:organization_count) { 2 }

      it "returns Users" do
        expect(helper.users_index_label).to eq("Users")
      end
    end

    context "when there are no organizations" do
      let(:organization_count) { 0 }

      it "returns nil" do
        expect(helper.users_index_label).to be_nil
      end
    end

    context "when there is one organization" do
      let(:organization_count) { 1 }

      it "returns the organization label" do
        expect(helper.users_index_label).to eq("#{organizations.first.abbreviation} Users")
      end
    end
  end
end
