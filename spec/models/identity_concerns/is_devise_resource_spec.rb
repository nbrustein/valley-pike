require "rails_helper"

RSpec.describe IdentityConcerns::IsDeviseResource, type: :model do
  describe ".find_for_database_authentication" do
    let!(:identity) do
      create(:identity, kind: "magic_link", email: "user@example.com")
    end

    context "when email is provided" do
      let(:result) { Identity.find_for_database_authentication(email: "USER@example.com") }

      it "finds the identity" do
        expect(result).to eq(identity)
      end
    end

    context "when email is not provided" do
      let(:result) { Identity.find_for_database_authentication(id: identity.id) }

      it "finds the identity" do
        expect(result).to eq(identity)
      end
    end
  end
end
