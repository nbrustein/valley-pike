require "rails_helper"
require "requests/requests_spec_helper"

RSpec.describe "Ride requests index", type: :request do
  include Devise::Test::IntegrationHelpers

  let(:headers) { request_headers }
  let(:organization) { create(:organization) }
  let(:role) { UserRole::VANITA_VIEWER }
  let(:current_user) { create_current_user_with_role(role:) }

  before { configure_request_host! }

  describe "GET /ride_requests" do
    let!(:ride_request_a) { create(:ride_request, organization:, date: 3.days.from_now, short_description: "Earlier date request") }
    let!(:ride_request_b) { create(:ride_request, organization:, date: 1.day.from_now, short_description: "Later date request") }

    context "when signed out" do
      let(:current_user) { nil }

      it "returns not found" do
        act
        expect(response).to have_http_status(:not_found)
      end
    end

    context "when the current user can't index ride requests" do
      let(:role) { UserRole::DRIVER }

      it "returns not found" do
        act
        expect(response).to have_http_status(:not_found)
      end
    end

    context "when the current user can index ride requests" do
      let(:role) { UserRole::VANITA_VIEWER }

      it "shows a list of ride requests ordered by date descending" do
        aggregate_failures do
          act
          expect(response).to have_http_status(:ok)
          expect(response.body).to include(ride_request_a.short_description)
          expect(response.body).to include(ride_request_b.short_description)
          expect(ride_request_a.date).to be > ride_request_b.date
          expect(short_descriptions.index(ride_request_a.short_description)).to be < short_descriptions.index(ride_request_b.short_description)
        end
      end
    end

    context "when the current user has access to multiple organizations" do
      let(:another_organization) { create(:organization) }
      let!(:ride_request_other_org) { create(:ride_request, organization: another_organization) }

      it "shows the organization abbreviation column" do
        act
        expect(page).to have_css("th", text: /org/i)
        row = page.find("tr[data-ride-request-id='#{ride_request_a.id}']")
        expect(row).to have_text(organization.abbreviation)
      end
    end

    context "when the current user has access to only one organization" do
      let(:role) { UserRole::RIDE_REQUESTER }
      let(:current_user) { create_current_user_with_role(role:, role_organization: organization) }
      let!(:ride_request_a) { create(:ride_request, organization:, date: 3.days.from_now, short_description: "Earlier date request") }
      let!(:ride_request_b) { create(:ride_request, organization:, date: 1.day.from_now, short_description: "Later date request") }

      it "does not show the organization abbreviation column" do
        act
        expect(page).not_to have_css("th", text: /org/i)
      end
    end
  end

  private

  def act
    sign_in current_user.identities.find_by!(kind: "magic_link") if current_user.present?
    get ride_requests_path, headers:
  end

  def create_current_user_with_role(role:, role_organization: nil)
    user = create(:user, email: "current-user@example.com")
    create(:user_role, user:, role:, organization: role_organization)
    create(:identity, :magic_link, user:, email: user.email)
    user
  end

  def short_descriptions
    page.all("tbody tr td:nth-child(2)").map {|node| node.text.strip }
  end

  def page
    @page ||= Capybara.string(response.body)
  end
end
