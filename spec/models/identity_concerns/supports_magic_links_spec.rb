require "rails_helper"

RSpec.describe IdentityConcerns::SupportsMagicLinks, type: :model do
  describe ".find_or_create_magic_link_identity!" do
    let(:email) { "User@Example.com" }

    context "when the email is new" do
      it "creates a user and identity", :aggregate_failures do
        expect {
          @identity = Identity.find_or_create_magic_link_identity!(email)
        }.to change(User, :count).by(1)
        .and change(Identity, :count).by(1)

        expect(@identity.user).to be_present
      end

      it "normalizes the email" do
        identity = Identity.find_or_create_magic_link_identity!(email)
        expect(identity.email).to eq('user@example.com')
      end
    end

    context "when the email already exists" do
      let!(:existing_identity) { Identity.find_or_create_magic_link_identity!("user@example.com") }

      it "does not create a user or identity" do
        expect { exec }
          .to change(User, :count).by(0)
          .and change(Identity, :count).by(0)
      end

      it "returns the existing identity" do
        result = exec
        expect(result).to eq(existing_identity)
      end

      def exec
        Identity.find_or_create_magic_link_identity!("USER@example.com")
      end
    end
  end

  describe "#magic_link_url" do
    let(:identity) { Identity.new(kind: "magic_link", email_normalized: "user@example.com") }
    let(:url) { identity.magic_link_url(host: "example.com", protocol: "https") }
    let(:uri) { URI.parse(url) }
    let(:params) { Rack::Utils.parse_nested_query(uri.query) }

    before do
      allow(identity).to receive(:encode_passwordless_token).and_return("token-123")
    end

    it "uses the provided scheme" do
      expect(uri.scheme).to eq("https")
    end

    it "uses the provided host" do
      expect(uri.host).to eq("example.com")
    end

    it "includes the identity email" do
      expect(params.dig("identity", "email")).to eq("user@example.com")
    end

    it "includes the identity token" do
      expect(params.dig("identity", "token")).to eq("token-123")
    end

    it "includes remember_me by default" do
      expect(params.dig("identity", "remember_me")).to eq("true")
    end
  end
end
