require "rails_helper"
require "requests/requests_spec_helper"

RSpec.describe "Magic link sign in", type: :request do
  let(:headers) { request_headers }

  before do
    configure_request_host!
    ActionMailer::Base.deliveries.clear
  end

  describe "POST /identity/magic_link_identity" do
    let(:email) { "User@Example.com" }
    let(:params) { { identity: { email: } } }

    context "when the email is present" do
      before { act }

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

    context "when the email is blank" do
      let(:email) { "" }

      before { act }

      it "returns an unprocessable entity response" do
        expect(response).to have_http_status(:unprocessable_content)
      end

      it "does not send an email" do
        expect(ActionMailer::Base.deliveries).to be_empty
      end
    end

    context "when the identity is inactive" do
      let(:identity) { build_stubbed(:identity, kind: "magic_link", email: "user@example.com") }

      before do
        allow(Identity).to receive(:find_or_create_magic_link_identity!).and_return(identity)
        allow(identity).to receive(:active_for_magic_link_authentication?).and_return(false)
        allow(identity).to receive(:magic_link_inactive_message).and_return(:inactive)
      end

      it "returns a forbidden response" do
        act
        expect(response).to have_http_status(:forbidden)
      end

      it "does not send an email" do
        expect(identity).not_to receive(:send_magic_link)
        act
      end
    end
  end

  def act
    post identity_magic_link_identity_path,
             params:,
             headers:
  end
end
