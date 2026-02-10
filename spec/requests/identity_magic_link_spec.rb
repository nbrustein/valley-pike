require "cgi"
require "rails_helper"
require "requests/requests_spec_helper"

RSpec.describe "Magic link sign in", type: :request do
  before do
    configure_request_host!
    ActionMailer::Base.deliveries.clear
  end

  # The POST endpoint is handled by the CreateMagicLinkIdentityController. This is what an unauthenticated
  # user hits to create a magic link identity.
  describe "POST /identity/magic_link_identity" do
    let(:email) { "User@Example.com" }
    let(:params) { {identity: {email:}} }

    context "when the email is present" do
      context "when there is a user for the email" do
        let(:user) { create(:user, email: "user@example.com") }

        before do
          user
          act
        end

        it "redirects" do
          expect(response).to have_http_status(:found)
        end

        it "creates a magic link identity" do
          identity = Identity.find_by(kind: "magic_link", email: "user@example.com")
          expect(identity).to be_present
        end

        it "sends a magic link email" do
          expect(ActionMailer::Base.deliveries.size).to eq(1)
        end
      end

      context "when there is no user for the email" do
        before { act }

        it "returns an unprocessable entity response" do
          expect(response).to have_http_status(:unprocessable_content)
        end

        it "renders the expected error" do
          expect(response.body).to include("Email not found")
        end

        it "does not send an email" do
          expect(ActionMailer::Base.deliveries).to be_empty
        end
      end
    end

    context "when the email is blank" do
      let(:email) { "" }

      before { act }

      it "returns an unprocessable entity response" do
        expect(response).to have_http_status(:unprocessable_content)
      end

      it "renders the expected error" do
        expect(CGI.unescapeHTML(response.body)).to include("Email can't be blank")
      end

      it "does not send an email" do
        expect(ActionMailer::Base.deliveries).to be_empty
      end
    end

    context "when the identity is inactive" do
      let(:user) { create(:user, email: "user@example.com") }
      let(:identity) { build_stubbed(:identity, kind: "magic_link", email: "user@example.com") }

      before do
        user
        allow(Identity).to receive(:find_or_create_magic_link_identity_for_user!).and_return(identity)
        allow(identity).to receive(:active_for_magic_link_authentication?).and_return(false)
        allow(identity).to receive(:magic_link_inactive_message).and_return(:inactive)
      end

      it "returns a forbidden response" do
        act
        expect(response).to have_http_status(:forbidden)
      end

      it "renders the expected error" do
        act
        expect(response.body).to include("inactive")
      end

      it "does not send an email" do
        expect(identity).not_to receive(:send_magic_link)
        act
      end
    end
  end

  # The GET endpoint is handled by the devise. This is where a magic link takes you
  describe "GET /identities/magic_link" do
    let(:identity) do
      identity = Identity.new(kind: "magic_link", email: "user@example.com")
      identity.save!(validate: false)
      identity
    end
    let(:uri) { URI.parse(identity.magic_link_url(host: "example.com", remember_me: false)) }
    let(:params) { Rack::Utils.parse_nested_query(uri.query.to_s) }

    it "creates a user for an identity without one" do
      get uri.path, params:, headers: request_headers

      identity.reload
      expect(identity.user).to be_present
      expect(identity.user.email).to eq("user@example.com")
    end
  end

  def act
    post identity_magic_link_identity_path,
         params:,
         headers: request_headers
  end
end
