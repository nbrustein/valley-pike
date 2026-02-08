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

  def post_login(params:, headers:)
    post identity_session_path, params: params, headers: headers
  end

  describe "POST /identity/sign_in" do
    let(:email) { "User@Example.com" }
    let(:params) { { identity: { email: email } } }

    context "when the email is present" do
      before do
        post_login(params: params, headers: headers)
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
        post_login(params: params, headers: headers)
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

        post_login(params: params, headers: headers)
      end

      it "returns a forbidden response" do
        expect(response).to have_http_status(:forbidden)
      end

      it "does not send an email" do
        expect(ActionMailer::Base.deliveries).to be_empty
      end
    end
  end

  describe "rate limiting" do
    let(:email) { "user@example.com" }
    let(:params) { { identity: { email: email } } }
    let(:attack_cache_store) { ActiveSupport::Cache::MemoryStore.new }
    let(:original_cache_store) { Rack::Attack.cache.store }

    before do
      Rack::Attack.cache.store = attack_cache_store
    end

    after do
      Rack::Attack.cache.store = original_cache_store
    end

    context "when a single email exceeds the limit" do
      let(:limit) { Rack::Attack::LOGIN_LIMIT_PER_EMAIL }

      before do
        limit.times { post_login(params: params, headers: headers) }
        post_login(params: params, headers: headers)
      end

      it "returns too many requests" do
        expect(response).to have_http_status(:too_many_requests)
      end
    end

    context "when a single IP exceeds the limit" do
      let(:limit) { Rack::Attack::LOGIN_LIMIT_PER_IP }
      let(:ip_headers) { headers.merge("REMOTE_ADDR" => "203.0.113.10") }

      before do
        limit.times { post_login(params: params, headers: ip_headers) }
        post_login(params: params, headers: ip_headers)
      end

      it "returns too many requests" do
        expect(response).to have_http_status(:too_many_requests)
      end
    end
  end
end
