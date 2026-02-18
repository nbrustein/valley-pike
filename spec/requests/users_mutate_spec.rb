require "rails_helper"
require "requests/requests_spec_helper"

RSpec.describe "UsersMutate", type: :request do
  include Devise::Test::IntegrationHelpers

  let(:headers) { request_headers }
  let(:current_user_organization) { nil }
  let(:current_user) do
    user = create(:user, email: "udo-admin@example.com")
    create(:user_role, user: user, role: current_user_role, organization: current_user_organization)
    create(:identity, :magic_link, user: user, email: user.email)
    user
  end
  let(:organization) { create(:organization, abbreviation: "UDO") }
  let(:current_user_role) { UserRole::VANITA_ADMIN }

  before { configure_request_host! }

  describe "GET /users/new" do
    
    context "when the current user is allowed to create users" do
      it "renders the header" do 
        # assert on ("Create...", "Invite....")
        raise NotImplementedError
      end
      
      it "renders the form" do
        assert_success { act(path: new_user_path) }
        expect(response.body).to include("form")
        # assert on the email field
        # assert on cancel button
        # assert on submit button
      end

      context "when the current user can only create ride requesters for a single organization" do
        it "renders the form with role and organization inputs" do
          raise NotImplementedError
        end
      end

      context "when the current user can add multiple roles for different organizations" do
        it "renders form elements for adding roles" do 
          raise NotImplementedError
        end
      end

    end

    context "when the current user is not allowed to create users" do
      let(:current_user_role) { UserRole::DRIVER }

      it "returns not found" do
        act(path: new_user_path)
        expect(response).to have_http_status(:not_found)
      end
    end

    def act(path:)
      sign_in current_user.identities.first
      get path, headers: headers
    end
  end

  describe "POST /users" do
    let(:valid_create_params) { {user: {email: "new.user@example.com", organization_id: organization.id}} }
    context "when the current user is allowed to create users" do
      it "creates a user" do
        act(path: users_path, params: valid_create_params)
        expect(response).to have_http_status(:ok)
      end

      context "when there are errors" do 
        it "renders the form with errors" do
          raise NotImplementedError
        end
      end
    end

    context "when the current user is not allowed to create users" do
      let(:current_user_role) { UserRole::DRIVER }
      it "returns not found" do
        act(path: users_path, params: valid_create_params)
        expect(response).to have_http_status(:not_found)
      end
    end

    def act(path:, params:)
      sign_in current_user.identities.first
      post path, params:, headers:
    end
  end
end
