require "rails_helper"

RSpec.describe UserRole do
  describe "organization validations" do
    let(:organization) { create(:organization) }

    context "when role requires organization" do
      context "with org_admin role" do
        let(:user_role) { build(:user_role, role: UserRole::ORG_ADMIN, organization: nil) }

        before { user_role.valid? }

        it "is invalid" do
          expect(user_role.errors[:organization]).to include("can't be blank")
        end
      end

      context "with ride_requester role" do
        let(:user_role) { build(:user_role, role: UserRole::RIDE_REQUESTER, organization: nil) }

        before { user_role.valid? }

        it "is invalid" do
          expect(user_role.errors[:organization]).to include("can't be blank")
        end
      end
    end

    context "when role forbids organization" do
      context "with developer role" do
        let(:user_role) { build(:user_role, role: UserRole::DEVELOPER, organization:) }

        before { user_role.valid? }

        it "is invalid" do
          expect(user_role.errors[:organization]).to include("must be blank")
        end
      end

      context "with vanita_admin role" do
        let(:user_role) { build(:user_role, role: UserRole::VANITA_ADMIN, organization:) }

        before { user_role.valid? }

        it "is invalid" do
          expect(user_role.errors[:organization]).to include("must be blank")
        end
      end
    end

    context "when role allows organization optional" do
      context "with driver role and no organization" do
        let(:user_role) { build(:user_role, role: UserRole::DRIVER, organization: nil) }

        it "is valid" do
          expect(user_role).to be_valid
        end
      end

      context "with driver role and organization" do
        let(:user_role) { build(:user_role, role: UserRole::DRIVER, organization:) }

        it "is valid" do
          expect(user_role).to be_valid
        end
      end
    end
  end
end
