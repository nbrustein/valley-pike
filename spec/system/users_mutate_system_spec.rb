require "rails_helper"
require "warden/test/helpers"

RSpec.describe "User create form", type: :system, js: true do
  include Warden::Test::Helpers

  let(:identity) do
    user = create(:user, email: "udo-admin@example.com")
    create(:user_role, user:, role: UserRole::DEVELOPER)
    create(:identity, :magic_link, user:, email: user.email)
  end

  before do
    login_as(identity, scope: :identity)
  end

  after do
    Warden.test_reset!
  end

  describe "user create form" do
    context "when a global role is selected that grants org admin privileges" do
      it "leaves Organization Roles section hidden" do
        visit new_user_path
        choose "Vanita admin"
        expect_org_admin_user_role_inputs(:hidden)
      end
    end

    context "when a global role is selected that does not grant org admin privileges" do
      let!(:organization) { create(:organization, name: "UDO Org", abbreviation: "UDO") }
      let!(:other_organization) { create(:organization, name: "VDO Org", abbreviation: "VDO") }
      let(:email) { "ride.requester@example.com" }

      it "reveals Organization Roles section which can be used to select an org admin role" do
        visit new_user_path
        act
        expect_user_to_have_roles(email, [ [ UserRole::RIDE_REQUESTER, organization.id ] ])
      end

      def act
        fill_in "Email", with: email

        # select a global role
        choose "None"
        expect_org_admin_user_role_inputs(:visible)

        # select an org admin role
        within_org_admin_row(organization.name) do
          select_radio_with_value("ride_requester")
        end
        click_button "Create ride requester"
      end
    end

    def expect_org_admin_user_role_inputs(visibility)
      visible = visibility == :visible ? true : false
      expect(page).to have_css("[data-org-admin-user-role-inputs]", visible:)
    end

    def within_org_admin_row(organization_name, &block)
      within(:xpath, "//tr[td[contains(., '#{organization_name}')]]", &block)
    end

    def select_radio_with_value(value)
      find("input[type='radio'][value='#{value}']").click
    end

    def expect_user_to_have_roles(email, role_pairs)
      user = User.find_by(email:)
      expect(user).to be_present
      expect(user.user_roles.map {|ur| [ ur.role, ur.organization_id ] }).to eq(role_pairs)
    end
  end
end
