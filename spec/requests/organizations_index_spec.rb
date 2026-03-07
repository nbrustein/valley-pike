require "rails_helper"
require "requests/requests_spec_helper"

RSpec.describe "Organizations index", type: :request do
  include Devise::Test::IntegrationHelpers

  let(:headers) { request_headers }
  let(:role) { UserRole::VANITA_VIEWER }
  let(:current_user) { create_current_user_with_role(role:) }
  let(:organization) { create(:organization) }

  before { configure_request_host! }

  describe "GET /organizations" do
    let!(:organization_a) { create(:organization, name: "Alpha Org", abbreviation: "AORG") }
    let!(:organization_b) { create(:organization, name: "Beta Org", abbreviation: "BORG") }

    context "when signed out" do
      let(:current_user) { nil }

      it "returns not found" do
        act
        expect(response).to have_http_status(:not_found)
      end
    end

    context "when the current_user can't index organizations" do
      let(:role) { UserRole::DRIVER }

      it "returns not found" do
        act
        expect(response).to have_http_status(:not_found)
      end
    end

    context "when the current_user can index organizations" do
      let(:role) { UserRole::VANITA_VIEWER }

      it "shows a list of organizations ordered by name" do
        aggregate_failures do
          act
          expect(response).to have_http_status(:ok)
          expect(response.body).to include(organization_a.name)
          expect(response.body).to include(organization_b.name)
          expect(organization_a.name).to be < organization_b.name
          expect(organization_names.index(organization_a.name)).to be < organization_names.index(organization_b.name)
        end
      end

      context "when an organization is editable" do
        let(:role) { UserRole::DEVELOPER }

        it "links the organization name to the edit page" do
          act
          row = page.find("tr[data-organization-id='#{organization_a.id}']")
          expect(row).to have_link(organization_a.name, href: edit_organization_path(id: organization_a.id))
        end
      end

      context "when an organization is not editable" do
        let(:role) { UserRole::VANITA_VIEWER }

        it "links to the show page with an eyeball icon" do
          act
          row = page.find("tr[data-organization-id='#{organization_a.id}']")
          expect(row).to have_link(href: organization_path(id: organization_a.id))
          expect(row).to have_css("i.fa-eye")
        end
      end
    end
  end

  private

  def act
    sign_in current_user.identities.find_by!(kind: "magic_link") if current_user.present?
    get organizations_path, headers: headers
  end

  def create_current_user_with_role(role:)
    user = create(
      :user,
      :with_identity,
      email: "current-user@example.com",
      role:,
      identity_kind: "magic_link",
      identity_email: "current-user@example.com"
    )
    user
  end

  def organization_names
    page.all("tbody tr td:first-child").map {|node| node.text.strip }
  end

  def page
    @page ||= Capybara.string(response.body)
  end
end
