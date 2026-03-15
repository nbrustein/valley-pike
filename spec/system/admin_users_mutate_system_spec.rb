require "rails_helper"
require "warden/test/helpers"

RSpec.describe "User mutate form", type: :system do
  include Warden::Test::Helpers

  let(:current_user_role) { UserRole::DEVELOPER }
  let(:current_user_role_organization) { nil }
  let(:email) { "new.user@example.com" }
  let(:full_name) { "Jane Doe" }
  let(:preferred_name) { "Jane" }
  let(:phone) { "" }
  let!(:organization) { create(:organization, name: "UDO Org", abbreviation: "UDO") }
  let(:identity) do
    user = create(
      :user,
      email: "udo-admin@example.com",
      role: current_user_role,
      role_organization: current_user_role_organization
    )
    create(:identity, :magic_link, user:, email: user.email)
  end

  before do
    login_as(identity, scope: :identity)
  end

  after do
    Warden.test_reset!
  end

  context "when creating a new user" do
    it "assigns basic field values to new user" do
      visit new_admin_user_path
      fill_in "Email", with: email
      fill_in "Full Name", with: "John Doe"
      expect(page).to have_field("Preferred Name", with: "John")
      choose "None"
      expect_org_admin_user_role_inputs(organizations: [ organization ])
      within_org_admin_row(organization.name) do
        select_radio_with_value("ride_requester")
      end

      click_button "Create ride requester"
      expect(page).to have_current_path(admin_users_path)

      user = User.find_by!(email:)
      expect(user.human.full_name).to eq("John Doe")
      expect(user.human.preferred_name).to eq("John")
    end
  end

  context "when editing an existing user" do
    let(:current_user_role) { UserRole::DEVELOPER }
    let(:current_user_role_organization) { nil }
    let(:target_user) do
      create(
        :user,
        email: "target.user@example.com",
        role: UserRole::RIDE_REQUESTER,
        role_organization: organization
      )
    end
    let(:updated_full_name) { "Updated Name" }
    let(:updated_preferred_name) { "Updated" }

    it "allows for updating a basic field" do
      visit edit_admin_user_path(id: target_user.id)
      expect(page).to have_field("Full Name", type: "text")
      fill_in "Full Name", with: updated_full_name
      choose "None"
      within_org_admin_row(organization.name) do
        select_radio_with_value("ride_requester")
      end
      click_button "Update user"

      expect(page).to have_current_path(admin_users_path)
      expect(target_user.reload.human.full_name).to eq(updated_full_name)
    end

    it "allows for updating a role" do
      visit edit_admin_user_path(id: target_user.id)
      choose "None"
      within_org_admin_row(organization.name) do
        select_radio_with_value("ride_requester")
      end
      click_button "Update user"

      expect(page).to have_current_path(admin_users_path)
      expect_user_to_have_roles(target_user.email, [ [ UserRole::RIDE_REQUESTER, organization.id ] ])
    end
  end

  context "when current user has permission to select any role" do
    let(:current_user_role) { UserRole::DEVELOPER }
    let(:current_user_role_organization) { nil }
    let!(:other_organization) { create(:organization, name: "VDO Org", abbreviation: "VDO") }

    it "allows for selecting an organization-specific admin role" do
      complete_form_with_org_specific_admin_role
      expect(page).to have_current_path(admin_users_path)
      expect_user_to_have_roles(email, [ [ UserRole::RIDE_REQUESTER, organization.id ] ])
    end

    it "allows for selecting a global admin role" do
      complete_form_with_global_admin_role
      expect(page).to have_current_path(admin_users_path)
      expect_user_to_have_roles(email, [ [ UserRole::VANITA_VIEWER, nil ] ])
    end

    it "allows for selecting a driver role" do
      complete_form_with_driver_role
      expect(page).to have_current_path(admin_users_path)
      expect_user_to_have_roles(email, [ [ UserRole::DRIVER, nil ] ])
    end

    def complete_form_with_org_specific_admin_role
      visit_and_fill_in_basic_fields

      # select a global role
      choose "None"
      expect_org_admin_user_role_inputs(organizations: [ organization, other_organization ])

      # select an org admin role
      within_org_admin_row(organization.name) do
        select_radio_with_value("ride_requester")
      end
      click_button "Create ride requester"
    end

    def complete_form_with_global_admin_role
      visit_and_fill_in_basic_fields

      choose "Vanita viewer"
      click_button "Create ride requester"
    end

    def complete_form_with_driver_role
      visit_and_fill_in_basic_fields

      choose "None" # select the required global role radio
      check "Driver"
      click_button "Create ride requester"
    end
  end

  def expect_org_admin_user_role_inputs(organizations:)
    inputs_section = page.find("[data-org-admin-user-role-inputs]", visible: :all)

    expect_org_admin_table_headers(inputs_section, [ "Organization", "None", "Org admin", "Ride requester" ])

    organizations.each do |organization|
      expect_organization_row(inputs_section, organization)
    end
  end

  def visit_and_fill_in_basic_fields
    visit new_admin_user_path
    expect(page).to have_field("Email", type: "email")
    fill_in "Email", with: email
    expect(page).to have_field("Full Name", type: "text")
    fill_in "Full Name", with: full_name
    expect(page).to have_field("Preferred Name", type: "text")
    fill_in "Preferred Name", with: preferred_name
    expect(page).to have_field("Phone", type: "tel")
    fill_in "Phone", with: phone if phone.present?
    expect(page).to have_checked_field("Send Login Link to User Email")
  end

  def expect_user_to_have_roles(email, role_pairs)
    user = User.find_by(email:)
    expect(user).to be_present
    expect(user.user_roles.map {|ur| [ ur.role, ur.organization_id ] }).to eq(role_pairs)
  end

  def expect_org_admin_table_headers(inputs_section, headers)
    headers.each do |header|
      expect(inputs_section).to have_css("th", text: header, visible: :all)
    end
  end

  def expect_organization_row(inputs_section, organization)
    row = inputs_section.find(
      :xpath,
      ".//tr[td[contains(., '#{organization.name}')]]",
      visible: :all
    )
    expect(row).to have_css("td", text: organization.name, visible: :all)
    expect(row).to have_css("input[type='radio'][value='']", count: 1, visible: :all)
    expect(row).to have_css("input[type='radio'][value='org_admin']", count: 1, visible: :all)
    expect(row).to have_css("input[type='radio'][value='ride_requester']", count: 1, visible: :all)
  end

  def within_org_admin_row(organization_name, &block)
    within(:xpath, "//tr[td[contains(., '#{organization_name}')]]", &block)
  end

  def select_radio_with_value(value)
    find("input[type='radio'][value='#{value}']").click
  end
end
