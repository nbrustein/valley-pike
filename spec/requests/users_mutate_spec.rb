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

      context "when the curent user can add a global role" do
        let(:current_user_role) { UserRole::DEVELOPER }

        it "renders the global role input" do
          assert_success { act(path: new_user_path) }
          expect(response.body).to have_css("input[name='user[global_role]'][type='radio']")

          expect_radio_option(
            field_name: "user[global_role]",
            value: "",
            label_text: "None",
            input_id: "user_global_role_none"
          )
          [ UserRole::VANITA_ADMIN, UserRole::VANITA_VIEWER ].each do |role|
            expect_radio_option(
              field_name: "user[global_role]",
              value: role,
              label_text: role.humanize,
              input_id: "user_global_role_#{role}"
            )
          end
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
              role: UserRole::VANITA_ADMIN,
              organization_id: nil,
            },
          ],
        },
      }
    end

    context "when the current user is allowed to create users" do
      let(:current_user_role) { UserRole::DEVELOPER }
      before { current_user } # make sure the current_user is created before we try to assert on the User count

      it "creates a user" do
        expect { assert_redirect_to_users_path }
          .to change(User, :count).by(1)

        created_user = User.find_by!(email: "new.user@example.com")
        expect(created_user.user_roles.pluck(:role, :organization_id))
          .to contain_exactly([ UserRole::VANITA_ADMIN, nil ])
      end

      def assert_redirect_to_users_path
        assert_redirect(to: users_path) {
          act(path: users_path, params: valid_create_params)
        }
      end

      context "when there are errors" do
        before do
          errors = ActiveModel::Errors.new(User.new)
          errors.add(:base, "An error occurred")
          result = UnitOfWork::Result.new(errors:)
          allow_any_instance_of(UnitsOfWork::CreateUser).to receive(:execute).and_return(UnitOfWork::Result.new(errors:))
        end

        it "renders the form with errors" do
          act(path: users_path, params: valid_create_params)

          expect(response).to have_http_status(:unprocessable_content)
          expect(response.body).to include("Please fix the following:")
          expect(response.body).to include("An error occurred")
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

  def assert_form_rendered
    expect(response.body).to include("form")
    expect(response.body).to have_css("input[name='user[email]'][type='email']")
    expect(response.body).to have_link("Cancel", href: users_path)
    expect(response.body).to have_button("Create ride requester")
  end
end
