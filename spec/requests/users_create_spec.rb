require "rails_helper"
require "requests/requests_spec_helper"

RSpec.describe "Users create", type: :request do
  include Devise::Test::IntegrationHelpers

  let(:headers) { request_headers }
  let(:organization) { create(:organization, name: "UDO Org", abbreviation: "UDO") }
  let(:other_organization) { create(:organization, name: "VDO Org", abbreviation: "VDO") }

  before { configure_request_host! }

  describe "GET /users/new" do
    context "when only one organization is available to the current user" do
      let(:current_user) { create(:user, email: "udo-admin@example.com") }

      before do
        create(:user_role, user: current_user, role: UserRole::ORG_ADMIN, organization:)
        create(:identity, :magic_link, user: current_user, email: current_user.email)
      end

      it "shows the create form without an organization select" do
        act_get_new(current_user:)

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Create ride requester")
        expect(response.body).not_to include("Select an organization")
      end
    end

    context "when multiple organizations are available to the current user" do
      let(:current_user) { create(:user, email: "vanita@example.com") }

      before do
        organization
        other_organization
        create(:user_role, user: current_user, role: UserRole::VANITA_ADMIN)
        create(:identity, :magic_link, user: current_user, email: current_user.email)
      end

      it "shows the organization select" do
        act_get_new(current_user:)

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Select an organization")
        expect(response.body).to include("UDO Org")
        expect(response.body).to include("VDO Org")
      end
    end

    context "when the current user is not allowed to create users" do
      let(:current_user) { create(:user, email: "requester@example.com") }

      before do
        create(:user_role, user: current_user, role: UserRole::RIDE_REQUESTER, organization:)
        create(:identity, :magic_link, user: current_user, email: current_user.email)
      end

      it "returns not found" do
        act_get_new(current_user:)

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "POST /users" do
    context "when the signed-in user is an org admin" do
      let(:current_user) { create(:user, email: "udo-admin@example.com") }

      before do
        create(:user_role, user: current_user, role: UserRole::ORG_ADMIN, organization:)
        create(:identity, :magic_link, user: current_user, email: current_user.email)
      end

      it "creates a ride requester for the organization" do
        expect { act_post_create(current_user:, params: {email: "new.requester@example.com"}) }
          .to change(User, :count).by(1)

        created_user = User.find_by!(email: "new.requester@example.com")
        expect(created_user.user_roles.pluck(:role, :organization_id))
          .to contain_exactly([ UserRole::RIDE_REQUESTER, organization.id ])
      end
    end

    context "when the signed-in user is a vanita admin" do
      let(:current_user) { create(:user, email: "vanita@example.com") }

      before do
        create(:user_role, user: current_user, role: UserRole::VANITA_ADMIN)
        create(:identity, :magic_link, user: current_user, email: current_user.email)
      end

      it "creates a ride requester for the selected organization" do
        expect { act_post_create(current_user:, params: {email: "vdo.requester@example.com", organization_id: other_organization.id}) }
          .to change(User, :count).by(1)

        created_user = User.find_by!(email: "vdo.requester@example.com")
        expect(created_user.user_roles.pluck(:role, :organization_id))
          .to contain_exactly([ UserRole::RIDE_REQUESTER, other_organization.id ])
      end
    end

    context "when the signed-in user is a ride requester" do
      let(:current_user) { create(:user, email: "requester@example.com") }

      before do
        create(:user_role, user: current_user, role: UserRole::RIDE_REQUESTER, organization:)
        create(:identity, :magic_link, user: current_user, email: current_user.email)
      end

      it "returns not found" do
        act_post_create(current_user:, params: {email: "blocked@example.com"})

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  private

  def act_get_new(current_user:)
    sign_in current_user.identities.find_by!(kind: "magic_link")
    get new_user_path, headers: headers
  end

  def act_post_create(current_user:, params:)
    sign_in current_user.identities.find_by!(kind: "magic_link")
    post users_path, params: {user: params}, headers: headers
  end
end
