require "rails_helper"
require "requests/requests_spec_helper"

RSpec.describe "OrganizationsMutate", type: :request do
  include Devise::Test::IntegrationHelpers

  let(:headers) { request_headers }
  let(:current_user) do
    create(
      :user,
      :with_identity,
      email: "org-admin@example.com",
      role: current_user_role,
      identity_kind: "magic_link",
      identity_email: "org-admin@example.com"
    )
  end
  let(:current_user_role) { UserRole::VANITA_ADMIN }
  let(:valid_create_params) do
    {
      organization: {
        name: "New Organization",
        abbreviation: "NEW",
        required_qualifications: [ DriverQualification::QUALIFICATION_CWS_VETTED ],
      },
    }
  end

  before { configure_request_host! }

  describe "GET /organizations/new" do
    context "when the current user is allowed to create organizations" do
      let(:current_user_role) { UserRole::DEVELOPER }

      it "renders the form" do
        assert_success { act(path: new_organization_path) }
        assert_form_rendered
      end
    end

    context "when the current user is not allowed to create organizations" do
      let(:current_user_role) { UserRole::DRIVER }

      it "returns not found" do
        act(path: new_organization_path)
        expect(response).to have_http_status(:not_found)
      end
    end

    def act(path:)
      sign_in current_user.identities.first
      get path, headers: headers
    end
  end

  describe "POST /organizations" do
    context "when the current user is allowed to create organizations" do
      let(:current_user_role) { UserRole::DEVELOPER }

      before do
        allow_any_instance_of(UnitsOfWork::CreateOrganization)
          .to receive(:execute)
          .and_return(UnitOfWork::Result.new(errors: ActiveModel::Errors.new(Organization.new)))
      end

      it "calls CreateOrganization and redirects to organizations_path" do
        assert_redirect(to: organizations_path) {
          act(path: organizations_path, params: valid_create_params)
        }
      end
    end

    context "when the current user is not allowed to create organizations" do
      let(:current_user_role) { UserRole::VANITA_VIEWER }

      it "returns not found" do
        act(path: organizations_path, params: valid_create_params)
        expect(response).to have_http_status(:not_found)
      end
    end

    def act(path:, params:)
      sign_in current_user.identities.first
      post path, params:, headers:
    end
  end

  describe "GET /organizations/:id/edit" do
    let!(:organization) do
      create(
        :organization,
        name: "Target Organization",
        abbreviation: "TGT",
        required_qualifications: required_qualifications
      )
    end
    let(:required_qualifications) { [] }
    let(:current_user_role) { UserRole::DEVELOPER }

    context "when the current user is allowed to update organizations" do
      it "renders the form" do
        assert_success { act(path: edit_organization_path(id: organization.id)) }
        expect(response.body).to include("Edit organization")
        assert_form_rendered(submit_text: "Update organization")
      end

      it "fills the fields with defaults from the organization" do
        assert_success { act(path: edit_organization_path(id: organization.id)) }

        aggregate_failures do
          expect(response.body).to have_field("Name", with: organization.name)
          expect(response.body).to have_field("Abbreviation", with: organization.abbreviation)
        end
      end

      context "when the organization requires CWS vetted" do
        let(:required_qualifications) { [ DriverQualification::QUALIFICATION_CWS_VETTED ] }

        it "checks the required qualifications checkbox" do
          assert_success { act(path: edit_organization_path(id: organization.id)) }

          expect(response.body).to have_css(
            "input[name='organization[required_qualifications][]'][type='checkbox'][checked]",
            visible: :all
          )
        end
      end

      context "when the organization has no required qualifications" do
        let(:required_qualifications) { [] }

        it "leaves the required qualifications checkbox unchecked" do
          assert_success { act(path: edit_organization_path(id: organization.id)) }

          aggregate_failures do
            expect(response.body).to have_css(
              "input[name='organization[required_qualifications][]'][type='checkbox']",
              visible: :all
            )
            expect(response.body).not_to have_css(
              "input[name='organization[required_qualifications][]'][type='checkbox'][checked]",
              visible: :all
            )
          end
        end
      end
    end

    context "when the current user is not allowed to update organizations" do
      let(:current_user_role) { UserRole::DRIVER }

      it "returns not found" do
        act(path: edit_organization_path(id: organization.id))
        expect(response).to have_http_status(:not_found)
      end
    end

    def act(path:)
      sign_in current_user.identities.first
      get path, headers: headers
    end
  end

  describe "PATCH /organizations/:id" do
    let!(:organization) { create(:organization, name: "Target Organization", abbreviation: "TGT") }
    let(:current_user_role) { UserRole::DEVELOPER }
    let(:update_params) do
      {
        organization: {
          name: "Updated Organization",
          abbreviation: "UPD",
          required_qualifications: [],
        },
      }
    end

    context "when the current user is allowed to update organizations" do
      before do
        allow_any_instance_of(UnitsOfWork::UpdateOrganization)
          .to receive(:execute)
          .and_return(UnitOfWork::Result.new(errors: ActiveModel::Errors.new(Organization.new)))
      end

      it "calls UpdateOrganization and redirects to organizations_path" do
        assert_redirect(to: organizations_path) {
          act(path: organization_path(id: organization.id), params: update_params)
        }
      end
    end

    context "when the current user is not allowed to update organizations" do
      let(:current_user_role) { UserRole::VANITA_VIEWER }

      it "returns not found" do
        act(path: organization_path(id: organization.id), params: update_params)
        expect(response).to have_http_status(:not_found)
      end
    end

    def act(path:, params:)
      sign_in current_user.identities.first
      patch path, params:, headers:
    end
  end

  describe "GET /organizations/:id" do
    let!(:organization) do
      create(
        :organization,
        name: "Target Organization",
        abbreviation: "TGT",
        required_qualifications: required_qualifications
      )
    end
    let(:required_qualifications) { [] }
    let(:current_user_role) { UserRole::VANITA_VIEWER }

    context "when signed out" do
      it "returns not found" do
        get organization_path(id: organization.id), headers: headers
        expect(response).to have_http_status(:not_found)
      end
    end

    context "when the current user cannot view organizations" do
      let(:current_user_role) { UserRole::DRIVER }

      it "returns not found" do
        act(path: organization_path(id: organization.id))
        expect(response).to have_http_status(:not_found)
      end
    end

    context "when the organization does not exist" do
      it "returns not found" do
        act(path: organization_path(id: 0))
        expect(response).to have_http_status(:not_found)
      end
    end

    context "when the current user can view organizations" do
      it "renders the organization name and abbreviation" do
        assert_success { act(path: organization_path(id: organization.id)) }

        aggregate_failures do
          expect(response.body).to include(organization.name)
          expect(response.body).to include(organization.abbreviation)
        end
      end

      it "links back to the organizations index" do
        assert_success { act(path: organization_path(id: organization.id)) }
        expect(response.body).to have_link("Back to organizations", href: organizations_path)
      end

      context "when the organization requires CWS vetted" do
        let(:required_qualifications) { [ DriverQualification::QUALIFICATION_CWS_VETTED ] }

        it "shows the CWS vetted qualification as checked" do
          assert_success { act(path: organization_path(id: organization.id)) }
          expect(response.body).to have_css("i.fa-square-check")
        end
      end

      context "when the organization has no required qualifications" do
        it "shows the CWS vetted qualification as unchecked" do
          assert_success { act(path: organization_path(id: organization.id)) }

          aggregate_failures do
            expect(response.body).to have_css("i.fa-square")
            expect(response.body).not_to have_css("i.fa-square-check")
          end
        end
      end
    end

    def act(path:)
      sign_in current_user.identities.first
      get path, headers: headers
    end
  end

  # These tests cover behavior that is shared between multiple endpoints
  describe "form rendering" do
    let(:current_user_role) { UserRole::DEVELOPER }

    context "when there are validation errors" do
      before do
        errors = ActiveModel::Errors.new(Organization.new)
        errors.add(:base, "An error occurred")
        allow_any_instance_of(UnitsOfWork::CreateOrganization)
          .to receive(:execute)
          .and_return(UnitOfWork::Result.new(errors:))
      end

      it "renders the filled in form with errors" do
        act(path: organizations_path, params: valid_create_params)

        expect(response).to have_http_status(:unprocessable_content)
        assert_form_rendered
        assert_form_filled_in
        expect(response.body).to include("Please fix the following:")
        expect(response.body).to include("An error occurred")
      end
    end

    context "when there is a runtime error" do
      before do
        allow_any_instance_of(UnitsOfWork::CreateOrganization)
          .to receive(:execute)
          .and_raise(StandardError, "Sensitive details")
      end

      it "renders the filled in form with a generic error" do
        act(path: organizations_path, params: valid_create_params)

        expect(response).to have_http_status(:unprocessable_content)
        assert_form_rendered
        assert_form_filled_in
        expect(response.body).to include("Please fix the following:")
        expect(response.body).to include("An error occurred")
        expect(response.body).not_to include("Sensitive details")
      end
    end

    def assert_form_filled_in
      expect(response.body).to have_field("Name", with: valid_create_params[:organization][:name])
      expect(response.body).to have_field("Abbreviation", with: valid_create_params[:organization][:abbreviation])
      expect(response.body).to have_css(
        "input[name='organization[required_qualifications][]'][type='checkbox'][checked]",
        visible: :all
      )
    end

    def act(path:, params:)
      sign_in current_user.identities.first
      post path, params:, headers:
    end
  end

  def assert_form_rendered(submit_text: "Create organization")
    expect(response.body).to include("form")
    expect(response.body).to have_css("input[name='organization[name]'][type='text']")
    expect(response.body).to have_css("input[name='organization[abbreviation]'][type='text']")
    expect(response.body).to have_css(
      "input[name='organization[required_qualifications][]'][type='checkbox'][value='#{DriverQualification::QUALIFICATION_CWS_VETTED}']",
      visible: :all
    )
    expect(response.body).to include("CWS vetted")
    expect(response.body).to have_link("Cancel", href: organizations_path)
    expect(response.body).to have_button(submit_text)
  end
end
