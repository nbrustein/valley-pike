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
        expect(page).to have_css("[data-org-admin-user-role-inputs]", visible: :hidden)
      end
    end

    context "when a global role is selected that does not grant org admin privileges" do
      let(:organization!) { create(:organization, name: "UDO Org", abbreviation: "UDO") }
      let!(:other_organization) { create(:organization, name: "VDO Org", abbreviation: "VDO") }

      it "reveals Organization Roles section" do
        visit new_user_path
        choose "None"

        expect(page).to have_css("[data-org-admin-user-role-inputs]", visible: true)
        

        first("[data-org-role-input]").click
        fill_in "Email", with: "ride.requester@example.com"
        click_button "Create ride requester"

        expect(page).to have_current_path("/users")
      end
    end
  end
end
