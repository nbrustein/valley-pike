require "rails_helper"
require "requests/requests_spec_helper"

RSpec.describe "App menu", type: :request do
  include Devise::Test::IntegrationHelpers

  let(:headers) { request_headers }
  let(:organization) { create(:organization, abbreviation: "UDO") }

  before { configure_request_host! }

  let!(:target_user) do
    target_user = create(:user)
    create(:user_role, user: target_user, role: UserRole::DRIVER)
    create(:identity, :magic_link, user: target_user, email: target_user.email)
    target_user
  end

  let(:current_user) do
    current_user = create(:user)
    create(:user_role, user: current_user, role: current_user_role)
    create(:identity, :magic_link, user: current_user, email: current_user.email)
    current_user
  end

  describe "navigation links" do
    let(:users_index_label) { "Users" }
    before do
      view_class = ApplicationController.view_context_class
      allow_any_instance_of(view_class)
        .to receive(:users_index_label)
        .and_return(users_index_label)
    end

    context "when the signed-in user has viewable users" do
      let(:current_user_role) { UserRole::DEVELOPER }

      it "shows the users link with the label" do
        act_get_profile(current_user:)
        page = Capybara.string(response.body)
        expect(page).to have_link(users_index_label, href: users_path)
      end
    end

    context "when the signed-in user has no viewable users" do
      let(:current_user_role) { UserRole::DRIVER }

      it "does not show the users link" do
        act_get_profile(current_user:)
        page = Capybara.string(response.body)
        expect(page).not_to have_link(users_index_label, href: users_path)
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
