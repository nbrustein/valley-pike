require "rails_helper"
require "requests/requests_spec_helper"

RSpec.describe "Home index", type: :request do
  include Devise::Test::IntegrationHelpers

  let(:headers) { request_headers }

  before { configure_request_host! }

  describe "GET /" do
    context "when signed out" do
      it "renders the welcome component" do
        get(root_path, headers:)
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Welcome")
      end
    end

    context "when signed in as a user with no special role" do
      let(:identity) do
        user = create(
          :user,
          :with_identity,
          identity_kind: "magic_link",
          identity_email: "user@example.com"
        )
        user.identities.first
      end

      it "renders the welcome component" do
        act
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Welcome")
      end
    end

    context "when signed in as a driver" do
      let(:organization) { create(:organization) }
      let(:identity) do
        user = create(
          :user,
          :with_identity,
          role: UserRole::DRIVER,
          identity_kind: "magic_link",
          identity_email: "driver@example.com"
        )
        user.identities.first
      end
      let!(:ride_request) { create(:ride_request, organization:) }

      it "renders the driver ride requests index component" do
        act
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Looking for Drivers")
      end
    end

    context "when signed in as a driver who also has another role" do
      let(:user) do
        create(:user, :with_identity,
          identity_kind: "magic_link",
          identity_email: "driver-admin@example.com")
      end
      let(:identity) { user.identities.first }

      before do
        create(:user_role, user:, role: UserRole::DRIVER)
        create(:user_role, user:, role: UserRole::VANITA_VIEWER)
      end

      it "renders the driver ride requests index component (driver takes priority)" do
        act
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("No ride requests available.")
      end
    end

    context "when signed in as a ride request viewer (non-driver)" do
      let(:identity) do
        user = create(
          :user,
          :with_identity,
          role: UserRole::VANITA_VIEWER,
          identity_kind: "magic_link",
          identity_email: "viewer@example.com"
        )
        user.identities.first
      end

      it "redirects to the admin ride requests index" do
        act
        expect(response).to redirect_to(admin_ride_requests_path)
      end
    end
  end

  private def act
    sign_in identity
    get root_path, headers:
  end
end
