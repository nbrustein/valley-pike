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
        assert_form_rendered
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
          full_name: "New User",
          preferred_name: "New",
          phone: "555-1212",
          global_role: UserRole::VANITA_ADMIN,
        },
      }
    end

    context "when the current user is allowed to create users" do
      let(:current_user_role) { UserRole::DEVELOPER }
      before { current_user } # make sure the current_user is created before we try to assert on the User count

      context "when there are validation errors" do
        before do
          errors = ActiveModel::Errors.new(User.new)
          errors.add(:base, "An error occurred")
          result = UnitOfWork::Result.new(errors:)
          allow_any_instance_of(UnitsOfWork::CreateUser).to receive(:execute).and_return(UnitOfWork::Result.new(errors:))
        end

        it "renders the form with errors" do
          act(path: users_path, params: valid_create_params)

          expect(response).to have_http_status(:unprocessable_content)
          assert_form_rendered
          expect(response.body).to include("Please fix the following:")
          expect(response.body).to include("An error occurred")
        end
      end

      context "when there is a runtime error" do
        before do
          allow_any_instance_of(UnitsOfWork::CreateUser).to receive(:execute)
            .and_raise(StandardError, "Sensitive details")
        end

        it "renders the form with a generic error" do
          act(path: users_path, params: valid_create_params)

          expect(response).to have_http_status(:unprocessable_content)
          assert_form_rendered
          expect(response.body).to include("Please fix the following:")
          expect(response.body).to include("An error occurred")
          expect(response.body).not_to include("Sensitive details")
        end
      end

      def assert_redirect_to_users_path
        assert_redirect(to: users_path) {
          act(path: users_path, params: valid_create_params)
        }
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

  def assert_form_rendered
    expect(response.body).to include("form")
    expect(response.body).to have_css("input[name='user[email]'][type='email']")
    expect(response.body).to have_link("Cancel", href: users_path)
    expect(response.body).to have_button("Create ride requester")
  end
end
