require "rails_helper"
require "warden/test/helpers"

RSpec.describe "Organization mutate form", type: :system do
  include Warden::Test::Helpers

  let(:current_user_role) { UserRole::DEVELOPER }
  let(:name) { "New Organization" }
  let(:abbreviation) { "NEW" }
  let(:identity) do
    user = create(
      :user,
      :with_identity,
      email: "org-admin@example.com",
      role: current_user_role,
      identity_kind: "magic_link",
      identity_email: "org-admin@example.com"
    )
    user.identities.find_by!(kind: "magic_link")
  end

  before do
    login_as(identity, scope: :identity)
  end

  after do
    Warden.test_reset!
  end

  context "when creating a new organization" do
    it "assigns basic field values to new organization" do
      visit new_organization_path
      fill_in "Name", with: name
      fill_in "Abbreviation", with: abbreviation
      check "CWS vetted"

      click_button "Create organization"
      expect(page).to have_current_path(organizations_path)

      organization = Organization.find_by!(abbreviation: abbreviation)
      expect(organization.name).to eq(name)
      expect(organization.required_qualifications).to contain_exactly(DriverQualification::QUALIFICATION_CWS_VETTED)
    end
  end

  context "when editing an organization" do
    let!(:organization) do
      create(
        :organization,
        name: "Old Organization",
        abbreviation: "OLD",
        required_qualifications: []
      )
    end

    it "allows for updating fields and required qualifications" do
      visit edit_organization_path(id: organization.id)
      fill_in "Name", with: "Updated Organization"
      fill_in "Abbreviation", with: "UPD"
      check "CWS vetted"

      click_button "Update organization"
      expect(page).to have_current_path(organizations_path)

      organization.reload
      expect(organization.name).to eq("Updated Organization")
      expect(organization.abbreviation).to eq("UPD")
      expect(organization.required_qualifications).to contain_exactly(DriverQualification::QUALIFICATION_CWS_VETTED)
    end
  end
end
