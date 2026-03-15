require "rails_helper"
require "requests/requests_spec_helper"

RSpec.describe "Users index", type: :request do
  include Devise::Test::IntegrationHelpers

  let(:headers) { request_headers }
  let(:organization) { create(:organization, abbreviation: "UDO") }
  let(:role) { UserRole::VANITA_ADMIN }
  let(:current_user) { create_current_user_with_role(role:) }

  before { configure_request_host! }

  describe "GET /admin/users" do
    let!(:user_1) do
      create(
        :user,
        role: UserRole::RIDE_REQUESTER,
        role_organization: user_1_role_organization,
        human: build(:human, full_name: "Andrew", preferred_name: "Yadawa")
      )
    end
    let!(:user_2) do
      create(
        :user,
        role: UserRole::RIDE_REQUESTER,
        role_organization: user_2_role_organization,
        human: build(:human, full_name: "Benita", preferred_name: "Xavier")
      )
    end
    let(:user_1_role_organization) { organization }
    let(:user_2_role_organization) { organization }

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

      it "shows a list of users ordered by full_name" do
        aggregate_failures do
          act
          expect(response).to have_http_status(:ok)
          expect(page).to have_text(user_2.human.full_name)
          expect(page).to have_text(user_1.human.full_name)
          expect(user_1.human.full_name).to be < user_2.human.full_name # sanity check
          expect(user_names.index(user_1.human.full_name)).to be < user_names.index(user_2.human.full_name)
        end
      end

      context "when a user is disabled" do
        let!(:disabled_user) do
          create(
            :user,
            disabled: true,
            role: UserRole::RIDE_REQUESTER,
            role_organization: organization,
            human: build(:human, full_name: "Disabled User", preferred_name: "Disabled")
          )
        end

        it "shows a disabled label next to their name" do
          act
          row = page.find("tr", text: disabled_user.human.full_name)
          expect(row.find("td:first-child")).to have_text("#{disabled_user.human.full_name} [DISABLED]")
        end
      end

      context "when a user is editable" do
        it "links row to the edit page" do
          act
          expect(page).to have_link(user_1.human.full_name, href: edit_admin_user_path(id: user_1.id))
        end
      end

      context "when a user is not editable" do
        let!(:user_3) { create(:user, email: "vanita.admin@example.com", role: UserRole::VANITA_ADMIN) }

        it "does not link row" do
          act
          expect(page).not_to have_link(user_3.human.full_name, href: edit_admin_user_path(id: user_3.id))
        end
      end

      context 'when the user can see users in all organizations' do
        let(:role) { UserRole::DEVELOPER }
        let(:another_organization) { create(:organization) }
        let(:user_1_role_organization) { organization }
        let(:user_2_role_organization) { another_organization }
        let!(:user_3) { create(:user, email: "user_3@example.com", role: UserRole::VANITA_VIEWER) }

        before { act }
        it 'shows a user whose role has an organization' do
          expect(page).to have_text(user_1.human.full_name)
        end
        it 'shows a user whose role has no organization' do
          expect(page).to have_text(user_3.human.full_name)
        end
      end

      context "when a user in the list has a single role" do
        let!(:single_role_user) { create(:user, email: "driver@example.com", role: UserRole::DRIVER) }
        let!(:single_role) { single_role_user.user_roles.first }
        before { act }

        it "shows the role pill" do
          row = page.find("tr", text: single_role_user.human.full_name)
          expect(row).to have_css("span", text: single_role.pill_label)
        end
      end

      context "when a user in the list has multiple roles" do
        let!(:multi_role_user) { create(:user, email: "multi-role@example.com") }
        let!(:multi_role_one) { create(:user_role, user: multi_role_user, role: UserRole::ORG_ADMIN, organization:) }
        let!(:multi_role_two) { create(:user_role, user: multi_role_user, role: UserRole::RIDE_REQUESTER, organization:) }
        before { act }

        it "shows all the role pills" do
          row = page.find("tr", text: multi_role_user.human.full_name)
          expect(row).to have_css("span", text: multi_role_one.pill_label)
          expect(row).to have_css("span", text: multi_role_two.pill_label)
        end
      end

      context "when a user in the list has no roles" do
        let!(:no_role_user) { create(:user, email: "no-roles@example.com") }
        before { act }

        it "shows no role pills" do
          row = page.find("tr[data-user-id='#{no_role_user.id}']")
          expect(row).not_to have_css("[data-role-pill]")
        end
      end
    end

    context 'when the current user can create users' do
      let(:role) { UserRole::VANITA_ADMIN }

      it "shows a create button that links to the new user page" do
        aggregate_failures do
          act
          expect(response).to have_http_status(:ok)
          expect(page).to have_link("Create", href: new_admin_user_path)
        end
      end
    end

    context "when the current user cannot create users" do
      let(:role) { UserRole::VANITA_VIEWER }

      it "does not show a create button" do
        aggregate_failures do
          act
          expect(response).to have_http_status(:ok)
          expect(page).not_to have_link("Create", href: new_admin_user_path)
        end
      end
    end
  end

  private

  def act
    sign_in current_user.identities.find_by!(kind: "magic_link") if current_user.present?
    get admin_users_path, headers:
  end

  def create_current_user_with_role(role:)
    user = create(:user, email: "current-user@example.com")
    role_attrs = {user:, role:}
    role_attrs[:organization] = organization if role.in?([ UserRole::ORG_ADMIN, UserRole::RIDE_REQUESTER ])
    create(:user_role, **role_attrs)
    create(:identity, :magic_link, user:, email: user.email)
    user
  end

  def page
    @page ||= Capybara.string(response.body)
  end

  def user_names
    page.all("tbody tr td:first-child").map {|node| node.text.strip }
  end
end
