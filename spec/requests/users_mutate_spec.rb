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
  let(:organization) { create(:organization, name: "UDO Org", abbreviation: "UDO") }
  let(:current_user_role) { UserRole::VANITA_ADMIN }

  before { configure_request_host! }

  describe "GET /users/new" do
    context "when the current user is allowed to create users" do
      it "renders the header" do
        assert_success { act(path: new_user_path) }
        expect(response.body).to include("Create ride requester")
        expect(response.body).to include("Invite a new ride requester by email.")
      end

      it "renders the form" do
        assert_success { act(path: new_user_path) }
        expect(response.body).to include("form")
        expect(response.body).to have_css("input[name='user[email]'][type='email']")
        expect(response.body).to have_link("Cancel", href: users_path)
        expect(response.body).to have_button("Create ride requester")
      end

      context "when the current user can only create ride requesters for a single organization" do
        let(:current_user_role) { UserRole::ORG_ADMIN }
        let(:current_user_organization) { organization }

        it "renders the form with hidden role and organization inputs" do
          raise NotImplementedError
          #   assert_success { act(path: new_user_path) }
          #   expect(response.body).to have_css(
          #     "input[name*='user_roles'][name$='[role]'][type='hidden']",
          #     visible: :all
          #   )
          #   expect(response.body).to have_css(
          #     "input[type='hidden'][value='#{organization.id}']",
          #     visible: :all
          #   )
          #   expect(response.body).not_to have_css("select[name*='user_roles'][name$='[organization_id]']")
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
    let(:valid_create_params) do
      {
        user: {
          email: "new.user@example.com",
          user_roles: [
            {
              role: UserRole::RIDE_REQUESTER,
              organization_id: organization.id,
            },
          ],
        },
      }
    end

    context "when the current user is allowed to create users" do
      let(:current_user_role) { UserRole::VANITA_ADMIN }

      it "creates a user" do
        expect { assert_redirect_to_users_path }
          .to change(User, :count).by(1)

        created_user = User.find_by!(email: "new.user@example.com")
        expect(created_user.user_roles.pluck(:role, :organization_id))
          .to contain_exactly([ UserRole::RIDE_REQUESTER, organization.id ])
      end

      def assert_redirect_to_users_path
        assert_redirect(to: users_path) {
          act(path: users_path, params: valid_create_params)
        }
      end

      context "when there are errors" do
        before do
          errors = ActiveModel::Errors.new(User.new)
          errors.add(:email, "already exists")
          result = UnitOfWork::Result.new(errors:)
          allow_any_instance_of(UnitsOfWork::CreateUser).to receive(:execute).and_return(UnitOfWork::Result.new(errors:))
        end

        it "renders the form with errors" do
          raise NotImplementedError # this won't work until we pass user_roles
          act(path: users_path, params: valid_create_params)

          expect(response).to have_http_status(:unprocessable_content)
          expect(response.body).to include("Please fix the following:")
          expect(response.body).to include("Email already exists")
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
