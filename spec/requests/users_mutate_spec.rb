require "rails_helper"
require "requests/requests_spec_helper"

RSpec.describe "UsersMutate", type: :request do
  include Devise::Test::IntegrationHelpers

  let(:headers) { request_headers }
  let(:current_user) do
    user = create(:user, email: "udo-admin@example.com", role: current_user_role)
    create(:identity, :magic_link, user:, email: user.email)
    user
  end
  let(:organization) { create(:organization, name: "UDO Org", abbreviation: "UDO") }
  let(:current_user_role) { UserRole::VANITA_ADMIN }
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
      get path, headers:
    end
  end

  describe "POST /users" do
    context "when the current user is allowed to create users" do
      let(:current_user_role) { UserRole::DEVELOPER }

      before do
        allow_any_instance_of(UnitsOfWork::CreateUser).to receive(:execute).and_return(UnitOfWork::Result.new(errors: ActiveModel::Errors.new(User.new)))
      end

      it "Calls CreateUser and redirects to users_path" do
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

  describe "GET /users/:id/edit" do
    let!(:target_user) do
      target_user = create(
        :user,
        email: "target.user@example.com",
        disabled: target_user_disabled,
        role: UserRole::RIDE_REQUESTER,
        role_organization: organization
      )
      if target_global_role.present?
        create(:user_role, user: target_user, role: target_global_role, organization: nil)
      end
      target_user.human.update!(
        full_name: "Target Full",
        preferred_name: "Target Preferred",
        phone: "555-555-5555"
      )
      target_user
    end
    let(:target_global_role) { nil }
    let(:target_user_disabled) { false }
    let(:target_human) { target_user.human }
    let(:current_user_role) { UserRole::DEVELOPER }

    context "when the current user is allowed to update the target user" do
      it "renders the form" do
        assert_success { act(path: edit_user_path(id: target_user.id)) }
        expect(response.body).to include("Edit user")
        assert_form_rendered(submit_text: "Update user")
      end

      it "renders the send login link button" do
        assert_success { act(path: edit_user_path(id: target_user.id)) }
        expect(response.body).to have_button("Send Login Link")
      end

      it "fills the human fields with defaults from the user" do
        assert_success { act(path: edit_user_path(id: target_user.id)) }

        aggregate_failures do
          expect(response.body).to have_field("Email", with: target_user.email)
          expect(response.body).to have_field("Full Name", with: target_human.full_name)
          expect(response.body).to have_field("Preferred Name", with: target_human.preferred_name)
          expect(response.body).to have_field("Phone", with: target_human.phone)
        end
      end

      context "when the target user is disabled" do
        let(:target_user_disabled) { true }

        it "checks the disable checkbox" do
          assert_success { act(path: edit_user_path(id: target_user.id)) }

          aggregate_failures do
            expect(response.body).to have_css("input[name='user[disabled]'][type='checkbox'][checked]", visible: :all)
            expect(response.body).to have_css("label", text: "Disable user")
          end
        end
      end

      context "when the target user is active" do
        let(:target_user_disabled) { false }

        it "leaves the disable checkbox unchecked" do
          assert_success { act(path: edit_user_path(id: target_user.id)) }

          aggregate_failures do
            expect(response.body).to have_css("input[name='user[disabled]'][type='checkbox']", visible: :all)
            expect(response.body).not_to have_css("input[name='user[disabled]'][type='checkbox'][checked]", visible: :all)
          end
        end
      end

      context "when the target user has no global role" do
        it "fills the role fields accordingly" do
          assert_success { act(path: edit_user_path(id: target_user.id)) }

          aggregate_failures do
            expect(response.body).to have_css(
              "input[name='user[global_role]'][value=''][checked]",
              visible: :all
            )
            assert_org_role_checked(organization:, role_value: UserRole::RIDE_REQUESTER)
          end
        end
      end

      context "when the target user has a global role" do
        let(:target_global_role) { UserRole::VANITA_VIEWER }

        it "fills the role fields accordingly" do
          assert_success { act(path: edit_user_path(id: target_user.id)) }

          aggregate_failures do
            expect(response.body).to have_css(
              "input[name='user[global_role]'][value='#{target_global_role}'][checked]",
              visible: :all
            )
            assert_org_role_checked(organization:, role_value: UserRole::RIDE_REQUESTER)
          end
        end
      end

      context "when the target user is disabled" do
        before { target_user.update!(disabled: true) }

        it "disables the send login link button" do
          assert_success { act(path: edit_user_path(id: target_user.id)) }
          expect(response.body).to have_button("Send Login Link", disabled: true)
        end
      end
    end

    context "when the current user is not allowed to update the target user" do
      let(:current_user_role) { UserRole::DRIVER }

      it "returns not found" do
        act(path: edit_user_path(id: target_user.id))
        expect(response).to have_http_status(:not_found)
      end
    end

    def act(path:)
      sign_in current_user.identities.first
      get path, headers:
    end

    def assert_org_role_checked(organization:, role_value:)
      page = Capybara.string(response.body)
      row = page.find(:xpath, ".//tr[td[contains(., '#{organization.name}')]]", visible: :all)
      expect(row).to have_css(
        "input[type='radio'][value='#{role_value}'][checked]",
        visible: :all
      )
    end
  end

  describe "PATCH /users/:id" do
    let(:target_user) do
      create(
        :user,
        email: "target.user@example.com",
        role: UserRole::RIDE_REQUESTER,
        role_organization: organization
      )
    end
    let(:current_user_role) { UserRole::DEVELOPER }
    let(:update_params) do
      {
        user: {
          global_role: "",
          org_admin_user_roles: {
            "1" => {
              role: UserRole::RIDE_REQUESTER,
              organization_id: organization.id,
            },
          },
        },
      }
    end

    context "when the current user is allowed to update the target user" do
      before do
        allow_any_instance_of(UnitsOfWork::UpdateUser)
          .to receive(:execute)
          .and_return(UnitOfWork::Result.new(errors: ActiveModel::Errors.new(User.new)))
      end

      it "calls UpdateUser and redirects to users_path" do
        assert_redirect(to: users_path) {
          act(path: user_path(id: target_user.id), params: update_params)
        }
      end
    end

    context "when the current user is not allowed to update the target user" do
      let(:current_user_role) { UserRole::DRIVER }

      it "returns not found" do
        act(path: user_path(id: target_user.id), params: update_params)
        expect(response).to have_http_status(:not_found)
      end
    end

    def act(path:, params:)
      sign_in current_user.identities.first
      patch path, params:, headers:
    end
  end

  describe "POST /users/:id/send_login_link" do
    let!(:target_user) { create(:user, email: "target.user@example.com", role: UserRole::DRIVER) }

    context "when the current user is allowed to send login links" do
      before do
        allow_any_instance_of(UnitsOfWork::SendUserLoginLink)
          .to receive(:execute)
          .and_return(UnitOfWork::Result.new(errors: ActiveModel::Errors.new(User.new)))
      end

      it "calls SendUserLoginLink and redirects to users_path" do
        assert_redirect(to: users_path) {
          act(path: send_login_link_user_path(id: target_user.id))
        }
        expect(flash[:notice]).to be_present
      end
    end

    context "when the current user is not allowed to send login links" do
      let(:current_user_role) { UserRole::DRIVER }

      it "returns not found" do
        act(path: send_login_link_user_path(id: target_user.id))
        expect(response).to have_http_status(:not_found)
      end
    end

    def act(path:)
      sign_in current_user.identities.first
      post path, headers:
    end
  end

  # These tests cover behavior that is shared between multiple endpoints
  describe "form rendering" do
    let(:current_user_role) { UserRole::DEVELOPER }

    context "when there are validation errors" do
      before do
        errors = ActiveModel::Errors.new(User.new)
        errors.add(:base, "An error occurred")
        result = UnitOfWork::Result.new(errors:)
        allow_any_instance_of(UnitsOfWork::CreateUser).to receive(:execute).and_return(UnitOfWork::Result.new(errors:))
      end

      it "renders the filled in form with errors" do
        act(path: users_path, params: valid_create_params)

        expect(response).to have_http_status(:unprocessable_content)
        assert_form_rendered
        assert_form_filled_in
        expect(response.body).to include("Please fix the following:")
        expect(response.body).to include("An error occurred")
      end
    end

    context "when there is a runtime error" do
      before do
        allow_any_instance_of(UnitsOfWork::CreateUser).to receive(:execute)
          .and_raise(StandardError, "Sensitive details")
      end

      it "renders the filled in form with a generic error" do
        act(path: users_path, params: valid_create_params)

        expect(response).to have_http_status(:unprocessable_content)
        assert_form_rendered
        assert_form_filled_in
        expect(response.body).to include("Please fix the following:")
        expect(response.body).to include("An error occurred")
        expect(response.body).not_to include("Sensitive details")
      end
    end

    def assert_form_filled_in
      # expect the value for email to be the one from the params
      expect(response.body).to have_field("Email", with: valid_create_params[:user][:email])
    end

    def act(path:, params:)
      sign_in current_user.identities.first
      post path, params:, headers:
    end
  end

  def assert_form_rendered(submit_text: "Create ride requester")
    expect(response.body).to include("form")
    expect(response.body).to have_css("input[name='user[email]'][type='email']")
    expect(response.body).to have_link("Cancel", href: users_path)
    expect(response.body).to have_button(submit_text)
  end
end
