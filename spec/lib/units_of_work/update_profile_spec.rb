require "rails_helper"

RSpec.describe UnitsOfWork::UpdateProfile do
  describe ".execute" do
    let(:user) { create(:user) }
    let(:new_email) { nil }
    let(:new_password) { nil }
    let(:new_password_confirmation) { new_password }

    context "when updating the user email" do
      let(:new_email) { "new-email@example.com" }

      it "updates the user email" do
        result = act
        assert_success(result)
        expect(user.reload.email).to eq(new_email)
      end

      context "when the user has a password identity" do
        let!(:password_identity) do
          create(:identity, user:, kind: "password", email: "user@example.com")
        end

        it "updates the password identity email" do
          result = act
          assert_success(result)
          expect(password_identity.reload.email).to eq("new-email@example.com")
        end
      end
    end

    context "when adding a password identity" do
      let(:new_password) { "An0therStr0ngPass!" }

      it "creates a password identity for the user" do
        result = act

        assert_success(result)
        password_identity = user.identities.find_by(kind: "password")
        expect(password_identity).to be_present
        expect(password_identity.email).to eq(user.email)
      end
    end

    context "when changing an existing password" do
      let!(:password_identity) do
        create(:identity, user:, kind: "password", email: "user@example.com")
      end
      let(:new_password) { "An0therStr0ngPass!" }

      it "updates the password identity password" do
        result = act

        assert_success(result)
        expect(password_identity.reload.valid_password?(new_password)).to be(true)
      end
    end

    context "when the password is invalid" do
      let!(:password_identity) do
        create(:identity, user:, kind: "password", email: "user@example.com")
      end
      let(:new_password) { "short" }

      it "returns errors" do
        result = act

        expect(result.success?).to be(false)
        expect(result.errors.full_messages).to include(
          "Password is too short (minimum is 12 characters)"
        )
      end
    end
  end

  private
  def act
    result = described_class.execute(
      user:,
      email: new_email,
      password: new_password,
      password_confirmation: new_password_confirmation
    )
  end

  def assert_success(result)
    expect(result.success?).to be(true), result.errors.full_messages.join(", ")
  end
end
