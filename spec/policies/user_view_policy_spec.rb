require "rails_helper"

RSpec.describe UserViewPolicy do
  let(:current_user_role) { nil }
  let(:current_user) { create(:user, role: current_user_role) }
  let(:policy) { UserViewPolicy.new(current_user, User) }
  let(:scope) { described_class::Scope.new(current_user, User).resolve }

  describe "#index?" do
    context "when the current user can index users" do
      let(:current_user_role) { UserRole::VANITA_ADMIN }

      it "returns true" do
        expect(policy.index?).to be(true)
      end
    end

    context "when the current user cannot index users" do
      let(:current_user) { nil }

      it "returns false" do
        expect(policy.index?).to be(false)
      end
    end
  end

  describe "#scope" do
    let!(:user_1) { create(:user) }
    let!(:user_2) { create(:user) }

    context "when the current user can index users" do
      let(:current_user_role) { UserRole::VANITA_ADMIN }

      it "returns all users" do
        expect(scope).to include(user_1, user_2)
      end
    end

    context "when the current user cannot index users" do
      let(:current_user_role) { UserRole::DRIVER }

      it "returns an empty query" do
        expect(scope).to be_empty
      end
    end
  end
end
