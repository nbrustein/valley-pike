require "rails_helper"

RSpec.describe IdentityConcerns::HasEmail, type: :model do
  describe ".normalize_email" do
    let(:raw_email) { "  Test@Example.Com " }

    it "downcases and trims whitespace" do
      expect(Identity.normalize_email(raw_email)).to eq("test@example.com")
    end
  end

  describe "#email=" do
    let(:identity) { build_stubbed(:identity, kind: "magic_link") }

    before do
      identity.email = "  Test@Example.Com "
    end

    it "stores a normalized email" do
      expect(identity.email).to eq("test@example.com")
    end
  end

  describe "#email_based?" do
    context "when the kind is one of EMAIL_BASED_KINDS" do
      let(:identity) { build_stubbed(:identity, kind: IdentityConcerns::HasEmail::EMAIL_BASED_KINDS.sample) }

      it "returns true" do
        expect(identity.email_based?).to be(true)
      end
    end

    context "when the kind is oauth" do
      let(:identity) { build_stubbed(:identity, kind: "oauth") }

      it "returns false" do
        expect(identity.email_based?).to be(false)
      end
    end
  end
end
