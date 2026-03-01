require "rails_helper"

RSpec.describe UnitsOfWork::SendUserLoginLink do
  describe ".execute" do
    let(:executor) { create(:user) }
    let(:user) { create(:user, email: "target.user@example.com") }
    let(:identity) { build_stubbed(:identity, :magic_link, user:, email: user.email) }
    let(:user_id) { user.id }

    context "when the user exists and the identity is active" do
      before do
        allow(Identity)
          .to receive(:find_or_create_magic_link_identity_for_user!)
          .with(user)
          .and_return(identity)
        allow(identity).to receive(:active_for_magic_link_authentication?).and_return(true)
        allow(identity).to receive(:send_magic_link)
      end

      it "sends the magic link" do
        result = act

        assert_success(result)
        expect(identity).to have_received(:send_magic_link)
      end
    end

    context "when the user does not exist" do
      let(:user_id) { SecureRandom.uuid }

      it "returns an error" do
        result = act

        expect(result.success?).to be(false)
        expect(result.errors.full_messages).to include("User not found")
      end
    end
  end

  private

  def act
    described_class.execute(
      executor_id: executor.id,
      params: {
        user_id:,
      }
    )
  end

  def assert_success(result)
    expect(result.success?).to be(true), result.errors.full_messages.join(", ")
  end
end
