require "rails_helper"
require "requests/requests_spec_helper"

RSpec.describe "App menu", type: :request do
  include Devise::Test::IntegrationHelpers

  let(:headers) { request_headers }
  let(:organization) { create(:organization, abbreviation: "UDO") }

  before { configure_request_host! }

  let!(:target_user) do
    target_user = create(
      :user,
      :with_identity,
      email: "target.user@example.com",
      identity_kind: "magic_link",
      identity_email: "target.user@example.com",
      role: UserRole::DRIVER
    )
    target_user
  end

  let(:current_user) do
    current_user = create(
      :user,
      :with_identity,
      email: "current.user@example.com",
      identity_kind: "magic_link",
      identity_email: "current.user@example.com",
      role: current_user_role
    )
    current_user
  end

  describe "navigation links" do
    context "when the signed-in user has viewable users" do
      let(:current_user_role) { UserRole::DEVELOPER }

      it "shows the users link with the label" do
        act_get_profile(current_user:)
        page = Capybara.string(response.body)
        expect(page).to have_link("Users", href: users_path)
      end
    end

    context "when the signed-in user has no viewable users" do
      let(:current_user_role) { UserRole::DRIVER }

      it "does not show the users link" do
        act_get_profile(current_user:)
        page = Capybara.string(response.body)
        expect(page).not_to have_link("Users", href: users_path)
      end
    end

    context "when the user is signed out" do
      it "does not show the edit profile link" do
        get profile_path, headers: headers
        expect(response.body).not_to include("Edit profile")
      end
    end

    context "when the user is signed in" do
      let(:current_user) { create(:user, email: "signed-in@example.com") }

      before do
        create(:identity, :magic_link, user: current_user, email: current_user.email)
      end

      it "shows the edit profile link" do
        act_get_profile(current_user:)
        expect(response.body).to include("Edit profile")
      end
    end
  end

  private

  def act_get_profile(current_user:)
    sign_in current_user.identities.find_by!(kind: "magic_link")
    get root_path, headers: headers
  end
end
