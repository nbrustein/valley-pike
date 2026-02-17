require "rails_helper"
require "requests/requests_spec_helper"

RSpec.describe "Users index", type: :request do
  include Devise::Test::IntegrationHelpers

  let(:headers) { request_headers }
  let(:organization) { create(:organization, abbreviation: "UDO") }
  let(:role) { UserRole::VANITA_ADMIN }
  let(:current_user) { create_current_user_with_role(role:) }

  before { configure_request_host! }

  describe "GET /users" do
    context "when signed out" do
      let(:current_user) { nil }

      it "returns not found" do
        act
        expect(response).to have_http_status(:not_found)
      end
    end

    context "when the current_user can't index users" do
      let(:role) { UserRole::DRIVER }

      it "returns not found" do
        act
        expect(response).to have_http_status(:not_found)
      end
    end

    context "when the current_user can index users" do
      let(:role) { UserRole::VANITA_ADMIN }

      let!(:zeta_user) do
        create(
          :user,
          human: build(:human, full_name: "Zeta Person", sortable_name: "Zeta")
        )
      end
      let!(:alpha_user) do
        create(
          :user,
          human: build(:human, full_name: "Alpha Person", sortable_name: "Alpha")
        )
      end
      let!(:alpha_user_role) { create(:user_role, user: alpha_user, role: UserRole::RIDE_REQUESTER, organization:) }
      let!(:zeta_user_role) { create(:user_role, user: zeta_user, role: UserRole::RIDE_REQUESTER, organization:) }

      context "when requesting the users index" do
        before { act }

        it "shows a list of users ordered by sortable name" do
          aggregate_failures do
            expect(response).to have_http_status(:ok)
            expect(response.body).to include(alpha_user.human.full_name)
            expect(response.body).to include(zeta_user.human.full_name)
            expect(alpha_user.human.sortable_name).to be < zeta_user.human.sortable_name # sanity check
            expect(response.body.index(alpha_user.human.full_name)).to be < response.body.index(zeta_user.human.full_name)
          end
        end

        it "shows a create button that links to the new user page" do
          aggregate_failures do
            expect(response).to have_http_status(:ok)
            expect(response.body).to include("Create")
            expect(response.body).to include(new_user_path)
          end
        end
      end

      context "when a user has a single role" do
        let!(:single_role_user) { create(:user, email: "driver@example.com") }
        let!(:single_role) { create(:user_role, user: single_role_user, role: UserRole::DRIVER, organization:) }
        before { act }

        it "shows the role pill" do
          expect(response.body).to match(user_row_with_role_labels_regex(
            full_name: single_role_user.human.full_name,
            role_labels: [ single_role.pill_label ]
          ))
        end
      end

      context "when a user has multiple roles" do
        let!(:multi_role_user) { create(:user, email: "multi-role@example.com") }
        let!(:multi_role_one) { create(:user_role, user: multi_role_user, role: UserRole::ORG_ADMIN, organization:) }
        let!(:multi_role_two) { create(:user_role, user: multi_role_user, role: UserRole::RIDE_REQUESTER, organization:) }
        before { act }

        it "shows all the role pills" do
          expect(response.body).to match(user_row_with_role_labels_regex(
            full_name: multi_role_user.human.full_name,
            role_labels: [ multi_role_one.pill_label, multi_role_two.pill_label ]
          ))
        end
      end

      context "when a user has no roles" do
        let!(:no_role_user) { create(:user, email: "no-roles@example.com") }
        before { act }

        it "shows no role pills" do
          expect(response.body).not_to include(no_role_user.human.full_name)
        end
      end
    end
  end

  private

  def act
    sign_in current_user.identities.find_by!(kind: "magic_link") if current_user.present?
    get users_path, headers: headers
  end

  def create_current_user_with_role(role:)
    user = create(:user, email: "current-user@example.com")
    role_attrs = {user:, role:}
    role_attrs[:organization] = organization if role.in?([ UserRole::ORG_ADMIN, UserRole::RIDE_REQUESTER ])
    create(:user_role, **role_attrs)
    create(:identity, :magic_link, user:, email: user.email)
    user
  end

  def user_row_with_role_labels_regex(full_name:, role_labels:)
    escaped_name = Regexp.escape(full_name)
    labels_pattern = role_labels.map {|label| Regexp.escape(label) }.join(".*?")

    /
      <tr[^>]*>
      .*?
      #{escaped_name}
      .*?
      #{labels_pattern}
      .*?
      <\/tr>
    /mx
  end

  def user_row_without_role_labels_regex(full_name:)
    escaped_name = Regexp.escape(full_name)

    /
      <tr[^>]*>
      .*?
      #{escaped_name}
      .*?
      <div[^>]*>
      \s*
      <\/div>
      .*?
      <\/tr>
    /mx
  end
end
