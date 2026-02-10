# frozen_string_literal: true

require "rails_helper"
require "requests/requests_spec_helper"

RSpec.describe "Profile", type: :request do
  include Devise::Test::IntegrationHelpers

  let(:headers) { request_headers }

  before { configure_request_host! }

  describe "GET /profile" do
    context "when the user has no password identity" do
      let(:identity) do
        user = create(
          :user,
          :with_identity,
          identity_kind: "magic_link",
          identity_email: "user@example.com"
        )
        user.identities.first
      end

      it "shows the add password heading and fields" do
        act_get_profile
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Add a password")
        expect(response.body).to include("name=\"profile[password]\"")
        expect(response.body).to include("name=\"profile[password_confirmation]\"")
      end
    end

    context "when the user has a password identity" do
      let(:identity) do
        user = create(
          :user,
          :with_identity,
          identity_kind: "password",
          identity_email: "user@example.com"
        )
        user.identities.first
      end

      it "shows the change password heading and fields" do
        act_get_profile
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Change password")
        expect(response.body).to include("name=\"profile[password]\"")
        expect(response.body).to include("name=\"profile[password_confirmation]\"")
      end
    end
  end

  describe "PATCH /profile" do
    let(:headers) { request_headers }
    let(:identity) { create(:identity, :magic_link, email: "user@example.com") }

    context "when the update succeeds" do
      it "redirects with a notice" do
        result = instance_double("UnitOfWork::Result", success?: true, errors: ActiveModel::Errors.new(User.new))
        allow(UnitsOfWork::UpdateProfile).to receive(:execute).and_return(result)

        act_patch_profile(profile_params: {email: "new@example.com"})

        expect(response).to redirect_to(profile_path)
      end
    end

    context "when the update fails" do
      it "renders errors" do
        errors = ActiveModel::Errors.new(User.new)
        errors.add(:password, "is too short (minimum is 12 characters)")
        result = instance_double("UnitOfWork::Result", success?: false, errors:)
        allow(UnitsOfWork::UpdateProfile).to receive(:execute).and_return(result)

        act_patch_profile(profile_params: {password: "short"})

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include("Password is too short (minimum is 12 characters)")
      end
    end
  end

  private

  def act_get_profile
    sign_in identity
    get profile_path, headers:
  end

  def act_patch_profile(profile_params:)
    sign_in identity
    patch profile_path, params: {profile: profile_params}, headers:
  end
end
