require "rails_helper"
require "requests/requests_spec_helper"

RSpec.describe "Users new", type: :request do
  include Devise::Test::IntegrationHelpers

  let(:headers) { request_headers }
  let(:organization) { create(:organization, name: "UDO Org", abbreviation: "UDO") }

  before { configure_request_host! }

  describe "GET /users/new" do
    context "when the current user is allowed to create users" do
      context "when the current user only has org admin permissions for one organization" do
        let(:current_user) { create(:user, email: "udo-admin@example.com") }
        let!(:other_organization) { create(:organization, name: "VDO Org", abbreviation: "VDO") }

        before do
          create(:user_role, user: current_user, role: UserRole::ORG_ADMIN, organization:)
          create(:identity, :magic_link, user: current_user, email: current_user.email)
        end

        it "renders the form with a hidden organization id" do
          act_get_new(current_user:)

          expect(response).to have_http_status(:ok)
          expect(response.body).to include("name=\"user[email]\"")
          expect(response.body).to include("name=\"user[role]\"")
          expect(response.body).to match(hidden_org_input_regex(organization.id))
          expect(response.body).not_to match(select_org_input_regex)
        end
      end

      context "when the current user can manage all users" do
        let(:current_user) { create(:user, email: "vanita-admin@example.com") }
        let!(:organization) { create(:organization, name: "UDO Org", abbreviation: "UDO") }
        let!(:other_organization) { create(:organization, name: "VDO Org", abbreviation: "VDO") }

        before do
          create(:user_role, user: current_user, role: UserRole::VANITA_ADMIN)
          create(:identity, :magic_link, user: current_user, email: current_user.email)
        end

        it "renders the form with an organization select" do
          act_get_new(current_user:)

          expect(response).to have_http_status(:ok)
          expect(response.body).to include("name=\"user[email]\"")
          expect(response.body).to include("name=\"user[role]\"")
          expect(response.body).to match(select_org_input_regex)
          expect(response.body).to include("UDO Org")
          expect(response.body).to include("VDO Org")
        end
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

  private

  def act_get_new(current_user:)
    sign_in current_user.identities.find_by!(kind: "magic_link")
    get new_user_path, headers: headers
  end

  def hidden_org_input_regex(organization_id)
    /
      <input
      (?=[^>]*name="user\[organization_id\]")
      (?=[^>]*type="hidden")
      (?=[^>]*value="#{organization_id}")
      [^>]*>
    /x
  end

  def select_org_input_regex
    /<select[^>]+name="user\[organization_id\]"/
  end
end
