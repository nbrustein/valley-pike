require "rails_helper"
require "requests/requests_spec_helper"

RSpec.describe "Home index", type: :request do
  include Devise::Test::IntegrationHelpers

  let(:headers) { request_headers }

  before { configure_request_host! }

  describe "GET /" do
    context "when signed out" do
      before do
        get root_path, headers:
      end

      it "returns ok" do
        expect(response).to have_http_status(:ok)
      end

      it "shows magic link and password sign-in options" do
        expect(response.body).to include("Sign in with a magic link")
        expect(response.body).to include("Sign in with password")
      end

      it "renders the password form with the correct action" do
        expect(response.body).to include(%(action="#{password_session_path}"))
      end

      it "renders the magic link form with the correct action" do
        expect(response.body).to include(%(action="#{identity_magic_link_identity_path}"))
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

      it "shows the signed-in state and sign-out button" do
        act
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Signed in as user@example.com")
        expect(response.body).to include(destroy_identity_session_path)
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

      it "renders the active ride requests page" do
        act
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Active Rides")
        expect(response.body).to include(ride_request.short_description)
      end
    end

    context "when signed in as a driver who also has another role" do
      let(:organization) { create(:organization) }
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

      it "renders the active ride requests page (driver takes priority)" do
        act
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Active Rides")
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
