require "rails_helper"
require "requests/requests_spec_helper"

RSpec.describe "Users index", type: :request do
  include Devise::Test::IntegrationHelpers

  let(:headers) { request_headers }
  let(:organization) { create(:organization, abbreviation: "UDO") }
  let(:other_organization) { create(:organization, abbreviation: "VDO") }

  before { configure_request_host! }

  describe "GET /users" do
    context "when signed out" do
      it "returns not found" do
        get users_path, headers: headers
        expect(response).to have_http_status(:not_found)
      end
    end

    context "when the signed-in user does not have org_admin permissions" do
      let(:user) { create(:user, email: "driver@example.com") }

      before do
        create(:user_role, user:, role: UserRole::DRIVER)
        create(:identity, :magic_link, user:, email: user.email)
      end

      it "returns not found" do
        act_get_users(user:)
        expect(response).to have_http_status(:not_found)
      end
    end

    context "when the signed-in user has global org_admin permissions" do
      let(:user) do
        create(
          :user,
          email: "vanita@example.com",
          human: build(:human, full_name: "Vanita Admin", sortable_name: "Vanita")
        )
      end
      let!(:alpha_user) { create(:user, email: "alpha@example.com", human: build(:human, full_name: "Alpha Person", sortable_name: "Alpha")) }
      let!(:zeta_user) { create(:user, email: "zeta@example.com", human: build(:human, full_name: "Zeta Person", sortable_name: "Zeta")) }
      let!(:nameless_user) { create(:user, email: "nameless@example.com") }

      before do
        nameless_user.human.destroy!
        create(:user_role, user:, role: UserRole::VANITA_ADMIN)
        create(:user_role, user: alpha_user, role: UserRole::DEVELOPER)
        create(:user_role, user: alpha_user, role: UserRole::ORG_ADMIN)
        create(:user_role, user: alpha_user, role: UserRole::DRIVER)
        create(:user_role, user: alpha_user, role: UserRole::ORG_ADMIN, organization:)
        create(:user_role, user: zeta_user, role: UserRole::DRIVER, organization:)
        create(:identity, :magic_link, user:, email: user.email)
      end

      it "shows all users with humans sorted by sortable name and role pills" do
        act_get_users(user:)

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Alpha Person")
        expect(response.body).to include("Vanita Admin")
        expect(response.body).to include("Zeta Person")
        expect(response.body).not_to include("nameless@example.com")

        expect(response.body.index("Alpha Person")).to be < response.body.index("Vanita Admin")
        expect(response.body.index("Vanita Admin")).to be < response.body.index("Zeta Person")

        expect(response.body).to include("dev")
        expect(response.body).to include("vanita")
        expect(response.body).to include("admin")
        expect(response.body).to include("driver")
        expect(response.body).to include("udo admin")
        expect(response.body).to include("udo driver")
      end
    end

    context "when the signed-in user only has organization-scoped org_admin permissions" do
      let(:user) { create(:user, email: "udo-admin@example.com") }
      let!(:udo_admin_user) { create(:user, human: build(:human, full_name: "UDO Admin", sortable_name: "Admin")) }
      let!(:vdo_admin_user) { create(:user, human: build(:human, full_name: "VDO Admin", sortable_name: "Admin")) }

      before do
        create(:user_role, user:, role: UserRole::ORG_ADMIN, organization:)
        create(:user_role, user: udo_admin_user, role: UserRole::ORG_ADMIN, organization:)
        create(:user_role, user: vdo_admin_user, role: UserRole::ORG_ADMIN, organization: other_organization)
        create(:identity, :magic_link, user:, email: user.email)
      end

      it "shows only users with org_admin roles in the same organization" do
        act_get_users(user:)

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("UDO Admin")
        expect(response.body).not_to include("VDO Admin")
      end
    end
  end

  private

  def act_get_users(user:)
    sign_in user.identities.find_by!(kind: "magic_link")
    get users_path, headers: headers
  end
end
