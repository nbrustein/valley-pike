require "rails_helper"
require "requests/requests_spec_helper"

RSpec.describe "Users create", type: :request do
  include Devise::Test::IntegrationHelpers

  let(:headers) { request_headers }
  let(:organization) { create(:organization, name: "UDO Org", abbreviation: "UDO") }
  let(:other_organization) { create(:organization, name: "VDO Org", abbreviation: "VDO") }

  before { configure_request_host! }


  describe "POST /users" do
    context "when the signed-in user is an org admin" do
      let(:current_user) { create(:user, email: "udo-admin@example.com") }

      before do
        create(:user_role, user: current_user, role: UserRole::ORG_ADMIN, organization:)
        create(:identity, :magic_link, user: current_user, email: current_user.email)
      end

      it "creates a ride requester for the organization" do
        expect { act_post_create(current_user:, params: {email: "new.requester@example.com", organization_id: organization.id}) }
          .to change(User, :count).by(1)

        created_user = User.find_by!(email: "new.requester@example.com")
        expect(created_user.user_roles.pluck(:role, :organization_id))
          .to contain_exactly([ UserRole::RIDE_REQUESTER, organization.id ])
      end
    end

    context "when the signed-in user is not allowed to create for the organization" do
      let(:current_user) { create(:user, email: "udo-admin@example.com") }

      before do
        create(:user_role, user: current_user, role: UserRole::ORG_ADMIN, organization:)
        create(:identity, :magic_link, user: current_user, email: current_user.email)
      end

      it "returns not found" do
        expect { act_post_create(current_user:, params: {email: "blocked@example.com", organization_id: other_organization.id}) }
          .not_to change(User, :count)

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  private

  def act_post_create(current_user:, params:)
    sign_in current_user.identities.find_by!(kind: "magic_link")
    post users_path, params: {user: params.merge(role: UserRole::RIDE_REQUESTER)}, headers: headers
  end
end
