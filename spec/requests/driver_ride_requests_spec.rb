require "rails_helper"
require "requests/requests_spec_helper"

RSpec.describe "Driver ride requests", type: :request do
  include Devise::Test::IntegrationHelpers

  let(:headers) { request_headers }
  let(:organization) { create(:organization) }

  before { configure_request_host! }

  describe "GET /driver/ride_requests/:id" do
    let(:ride_request) { create(:ride_request, organization:) }

    context "when signed out" do
      it "returns not found" do
        act(ride_request)
        expect(response).to have_http_status(:not_found)
      end
    end

    context "when the user is not a driver" do
      let(:current_user) do
        create(:user, :with_identity,
          role: UserRole::VANITA_VIEWER,
          identity_kind: "magic_link",
          identity_email: "viewer@example.com")
      end

      it "returns not found" do
        sign_in current_user.identities.first
        act(ride_request)
        expect(response).to have_http_status(:not_found)
      end
    end

    context "when the driver can see the ride request" do
      let(:current_user) do
        create(:user, :with_identity,
          role: UserRole::DRIVER,
          identity_kind: "magic_link",
          identity_email: "driver@example.com")
      end

      it "renders the show page" do
        sign_in current_user.identities.first
        act(ride_request)
        expect(response).to have_http_status(:ok)
        expect(response.body).to include(ride_request.short_description)
      end
    end

    context "when the driver cannot see the ride request" do
      let(:current_user) do
        create(:user, :with_identity,
          role: UserRole::DRIVER,
          identity_kind: "magic_link",
          identity_email: "driver@example.com")
      end
      let(:org_with_quals) do
        create(:organization,
          required_qualifications: [ DriverQualification::QUALIFICATION_CWS_VETTED ])
      end
      let(:ride_request) do
        create(:ride_request, organization: org_with_quals, date: 1.day.from_now)
      end

      it "returns not found" do
        sign_in current_user.identities.first
        act(ride_request)
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  private

  def act(ride_request)
    get(driver_ride_request_path(id: ride_request.id), headers:)
  end
end
