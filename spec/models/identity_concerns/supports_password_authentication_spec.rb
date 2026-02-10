require "rails_helper"

RSpec.describe IdentityConcerns::SupportsPasswordAuthentication do
  describe "password validations" do
    let(:email) { "user@example.com" }
    let(:kind) { "password" }
    let(:password) { "Str0ngPassw0rd!" }
    let(:password_confirmation) { password }
    let(:identity) do
      build(
        :identity,
        kind:,
        email:,
        password:,
        password_confirmation:
      )
    end

    context "when the kind is password" do
      context "when the password is blank" do
        let(:password) { "" }
        let(:password_confirmation) { "" }

        it "is valid" do
          expect(identity).to be_valid
        end
      end

      context "when the password is too short" do
        let(:password) { "Short1!" }

        it "adds a length error" do
          identity.valid?
          expect(identity.errors[:password]).to include("is too short (minimum is 12 characters)")
        end
      end

      context "when the password lacks strength" do
        let(:password) { "aaaaaaaaaaaa" }

        it "adds a strength error" do
          identity.valid?
          expect(identity.errors[:password]).to include(
            "must be at least 12 characters and include upper, lower, number, and symbol"
          )
        end
      end

      context "when password strength validation is skipped" do
        let(:password) { "aaaaaaaaaaaa" }

        before do
          identity.skip_password_strength_validation = true
        end

        it "does not add a strength error" do
          identity.valid?
          expect(identity.errors[:password]).not_to include(
            "must be at least 12 characters and include upper, lower, number, and symbol"
          )
        end
      end

      context "when password validation is skipped" do
        let(:password) { nil }
        let(:password_confirmation) { nil }

        before do
          identity.skip_password_validation = true
        end

        it "does not add a password error" do
          identity.valid?
          expect(identity.errors[:password]).to be_empty
        end
      end
    end

    context "when the kind is not password" do
      let(:kind) { "magic_link" }
      let(:password) { nil }
      let(:password_confirmation) { nil }

      it "does not add a password error" do
        identity.valid?
        expect(identity.errors[:password]).to be_empty
      end
    end
  end
end
