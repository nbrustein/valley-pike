require "rails_helper"
require "warden/test/helpers"

RSpec.describe "User create form", type: :system, js: true do
  include Warden::Test::Helpers

  let(:current_user_role) { UserRole::ORG_ADMIN }
  let(:current_user_role_organization) { organization }
  let(:email) { "new.user@example.com" }
  let(:full_name) { "Jane Doe" }
  let(:preferred_name) { "Jane" }
  let(:phone) { "" }
  let!(:organization) { create(:organization, name: "UDO Org", abbreviation: "UDO") }
  let(:identity) do
    user = create(:user, email: "udo-admin@example.com")
    create(:user_role, user:, role: current_user_role, organization: current_user_role_organization)
    create(:identity, :magic_link, user:, email: user.email)
  end

  before do
    login_as(identity, scope: :identity)
  end

  after do
    Warden.test_reset!
  end

  it "assigns basic field values to new user" do
    visit new_user_path
    fill_in "Email", with: email
    fill_in "Full Name", with: "John Doe"

    click_button "Create ride requester"

    user = User.find_by!(email:)
    expect(user.human.full_name).to eq("John Doe")
    expect(user.human.preferred_name).to eq("John")
  end

  context "when current user has permission to select any role" do
    let(:current_user_role) { UserRole::DEVELOPER }
    let(:current_user_role_organization) { nil }
    let!(:other_organization) { create(:organization, name: "VDO Org", abbreviation: "VDO") }

    it "allows for selecting an org admin role" do
      act
      expect(page).to have_current_path(users_path)
      expect_user_to_have_roles(email, [ [ UserRole::RIDE_REQUESTER, organization.id ] ])
    end

    def act
      visit_and_fill_in_basic_fields

      # select a global role
      choose "None"
      expect_org_admin_user_role_inputs(:visible)

      # select an org admin role
      within_org_admin_row(organization.name) do
        select_radio_with_value("ride_requester")
      end
      click_button "Create ride requester"
    end

    def within_org_admin_row(organization_name, &block)
      within(:xpath, "//tr[td[contains(., '#{organization_name}')]]", &block)
    end

    def select_radio_with_value(value)
      find("input[type='radio'][value='#{value}']").click
    end
  end

  context "when current user only has permissions to assign ride requester role" do
    let(:current_user_role) { UserRole::ORG_ADMIN }
    let(:current_user_role_organization) { organization }

    it "does not show any role inputs and creates a user with the ride requester role" do
      act
      expect(page).to have_current_path(users_path)
      expect_user_to_have_roles(email, [ [ UserRole::RIDE_REQUESTER, organization.id ] ])
    end

    def act
      visit_and_fill_in_basic_fields
      click_button "Create ride requester"
    end
  end

  def expect_org_admin_user_role_inputs(visibility)
    visible = visibility == :visible ? true : false
    expect(page).to have_css("[data-org-admin-user-role-inputs]", visible:)
  end

  def visit_and_fill_in_basic_fields
    visit new_user_path
    fill_in "Email", with: email
    fill_in "Full Name", with: full_name
    fill_in "Preferred Name", with: preferred_name
    fill_in "Phone", with: phone if phone.present?
  end

  def expect_user_to_have_roles(email, role_pairs)
    user = User.find_by(email:)
    expect(user).to be_present
    expect(user.user_roles.map {|ur| [ ur.role, ur.organization_id ] }).to eq(role_pairs)
  end
end
