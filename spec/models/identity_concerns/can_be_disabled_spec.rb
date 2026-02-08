require "rails_helper"

RSpec.describe IdentityConcerns::CanBeDisabled, type: :model do
  describe "#active_for_authentication?" do
    let(:identity) { Identity.new(disabled_at: disabled_at) }
    let(:user) { build_stubbed(:user, disabled_at: user_disabled_at) }
    let(:user_disabled_at) { nil }
    let(:disabled_at) { nil }

    before do
      identity.user = user
    end

    context "when identity and user are not disabled" do
      it "returns true" do
        expect(identity.active_for_authentication?).to be(true)
      end
    end

    context "when the identity is disabled" do
      let(:disabled_at) { Time.current }

      it "returns false" do
        expect(identity.active_for_authentication?).to be(false)
      end
    end

    context "when the user is disabled" do
      let(:user_disabled_at) { Time.current }

      it "returns false" do
        expect(identity.active_for_authentication?).to be(false)
      end
    end
  end

  describe "#active_for_magic_link_authentication?" do
    context "when the identity is disabled" do
      let(:user) { build_stubbed(:user, disabled_at: nil) }
      let(:identity) { Identity.new(kind: "magic_link", email_normalized: "a@example.com", disabled_at: Time.current) }

      before do
        identity.user = user
      end

      it "returns false" do
        expect(identity.active_for_magic_link_authentication?).to be(false)
      end
    end

    context "when the user is disabled" do
      let(:user) { build_stubbed(:user, disabled_at: Time.current) }
      let(:identity) { Identity.new(kind: "magic_link", email_normalized: "a@example.com") }

      before do
        identity.user = user
      end

      it "returns false" do
        expect(identity.active_for_magic_link_authentication?).to be(false)
      end
    end
  end
end
