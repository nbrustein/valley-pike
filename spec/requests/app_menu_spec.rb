require "rails_helper"
require "requests/requests_spec_helper"

RSpec.describe "App menu", type: :request do
  include Devise::Test::IntegrationHelpers

  let(:headers) { request_headers }
  let(:organization) { create(:organization, abbreviation: "UDO") }

  before { configure_request_host! }

  describe "navigation links" do
    context "when the signed-in user is an org admin with ride requesters" do
      let(:current_user) { create(:user, email: "udo-admin@example.com") }
      let!(:ride_requester) { create(:user) }

      before do
        create(:user_role, user: current_user, role: UserRole::ORG_ADMIN, organization:)
        create(:user_role, user: ride_requester, role: UserRole::RIDE_REQUESTER, organization:)
        create(:identity, :magic_link, user: current_user, email: current_user.email)
      end

      it "shows the users link" do
        act_get_profile(current_user:)
        expect(response.body).to include("UDO Users")
      end
    end

    context "when the signed-in user is an org admin with no ride requesters" do
      let(:current_user) { create(:user, email: "no-requesters@example.com") }

      before do
        create(:user_role, user: current_user, role: UserRole::ORG_ADMIN, organization:)
        create(:identity, :magic_link, user: current_user, email: current_user.email)
      end

      it "does not show the users link" do
        act_get_profile(current_user:)
        expect(response.body).not_to include("UDO Users")
      end
    end

    context "when the user is signed out" do
      it "does not show the edit profile link" do
        get profile_path, headers: headers
        expect(response.body).not_to include("Edit profile")
      end
    end

    context "when the user is signed in" do
      let(:current_user) { create(:user, email: "signed-in@example.com") }

      before do
        create(:identity, :magic_link, user: current_user, email: current_user.email)
      end

      it "shows the edit profile link" do
        act_get_profile(current_user:)
        expect(response.body).to include("Edit profile")
      end
    end
  end

  private

  def act_get_profile(current_user:)
    sign_in current_user.identities.find_by!(kind: "magic_link")
    get profile_path, headers: headers
  end
end
