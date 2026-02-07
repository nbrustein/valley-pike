require "rails_helper"

RSpec.describe "Magic link sign in", type: :request do
  let(:headers) do
    {
      "User-Agent" => "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
      "HTTP_USER_AGENT" => "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
    }
  end

  before do
    Rails.application.config.hosts.clear
    ActionMailer::Base.deliveries.clear
    host! "example.com"
  end

  describe "POST /identity/sign_in" do
    let(:email) { "User@Example.com" }
    let(:params) { { identity: { email: email } } }

    context "when the email is present" do
      before do
        post identity_session_path,
             params: params,
             headers: headers
      end

      it "redirects" do
        expect(response).to have_http_status(:found)
      end

      it "creates a magic link identity" do
        identity = Identity.find_by(kind: "magic_link", email_normalized: "user@example.com")

        expect(identity).to be_present
      end

      it "sends a magic link email" do
        expect(ActionMailer::Base.deliveries.size).to eq(1)
      end
    end

    context "when the email is blank" do
      let(:email) { "" }

      before do
        post identity_session_path,
             params: params,
             headers: headers
      end

      it "returns an unprocessable entity response" do
        expect(response).to have_http_status(:unprocessable_content)
      end

      it "does not send an email" do
        expect(ActionMailer::Base.deliveries).to be_empty
      end
    end

    context "when the identity is inactive" do
      let(:identity) { Identity.new(kind: "magic_link", email_normalized: "user@example.com") }

      before do
        allow(Identity).to receive(:find_or_create_magic_link_identity!).and_return(identity)
        allow(identity).to receive(:active_for_magic_link_authentication?).and_return(false)
        allow(identity).to receive(:magic_link_inactive_message).and_return(:inactive)
        expect(identity).not_to receive(:send_magic_link)

        post identity_session_path,
             params: params,
             headers: headers
      end

      it "returns a forbidden response" do
        expect(response).to have_http_status(:forbidden)
      end

      it "does not send an email" do
        expect(ActionMailer::Base.deliveries).to be_empty
      end
    end
  end
end
