require "rails_helper"
require "requests/requests_spec_helper"

RSpec.describe "Password sign in", type: :request do
  let(:headers) { request_headers }

  before { configure_request_host! }

  describe "POST /auth/password_session" do
    let(:params) { { identity: { email:, password:, kind: "password" } } }
    let(:password) { "Str0ngPassw0rd!" }

    context "with missing email" do
      let(:email) { "" }

      it "shows error" do
        act
        assert_error_shown("Email can't be blank")
      end
    end

    context "with missing password" do
      let(:email) { "user@example.com" }
      let(:password) { "" }

      it "shows error" do
        act
        assert_error_shown("Password can't be blank")
      end
    end

    context "with invalid email/password" do
      let(:email) { "user@example.com" }
      let(:password) { "WrongPassword123!" }

      before { create_identity(email:, password: "ActualPassword123!") }

      it "shows error" do
        act
        expect(response).to have_http_status(:found)
        expect(response).to redirect_to(new_identity_session_path)
        expect(flash[:alert]).to be_present
      end
    end

    context "with valid email/password" do
      let(:email) { "user@example.com" }
      before { create_identity(email:, password:) }

      it "redirects and shows flash message" do
        act
        expect(response).to have_http_status(:found)
        expect(response).to redirect_to(root_path)
        expect(flash[:notice]).to be_present
      end
    end
  end

  private def act
    post password_session_path,
         params:,
         headers:
  end

  private def assert_error_shown(message)
    expect(response).to have_http_status(:unprocessable_content)
    expect(CGI.unescapeHTML(response.body)).to include(message)
  end

  private def create_identity(email:, password:)
    user = create(:user)
    create(
      :identity,
      user:,
      kind: "password",
      email:,
      password:,
      password_confirmation: password
    )
  end
end
