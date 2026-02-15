require "rails_helper"

RSpec.describe UnitsOfWork::CreateUser do
  describe ".execute" do
    let(:executor) { create(:user) }
    let(:organization) { create(:organization, abbreviation: "UDO") }
    let(:email) { "new.user@example.com" }
    let(:full_name) { "New User" }
    let(:phone) { "555-1212" }
    let(:sortable_name) { "User" }
    let(:roles) do
      [
        {role: UserRole::ORG_ADMIN, organization_id: organization.id},
        {role: UserRole::DRIVER, organization_id: nil}
      ]
    end
    let(:password) { nil }

    context "when the user does not exist" do
      it "creates a user with a human and roles" do
        result = act

        assert_success(result)

        user = User.find_by(email:)
        expect(user).to be_present
        expect(user.human.full_name).to eq(full_name)
        expect(user.human.phone).to eq(phone)
        expect(user.human.sortable_name).to eq(sortable_name)
        expect(user.user_roles.pluck(:role, :organization_id)).to contain_exactly(
          [ UserRole::ORG_ADMIN, organization.id ],
          [ UserRole::DRIVER, nil ]
        )
      end

      context "when a password is provided" do
        let(:password) { "An0therStr0ngPass!" }

        it "creates a password identity" do
          result = act

          assert_success(result)
          user = User.find_by!(email:)
          identity = user.identities.find_by(kind: "password")

          expect(identity).to be_present
          expect(identity.email).to eq(email)
          expect(identity.valid_password?(password)).to be(true)
        end
      end
    end

    context "when the user already exists" do
      before { create(:user, email:) }

      it "returns an error" do
        result = act

        expect(result.success?).to be(false)
        expect(result.errors.full_messages).to include("Email already exists")
      end
    end
  end

  private

  def act
    described_class.execute(
      executor_id: executor.id,
      params: {
        email:,
        full_name:,
        phone:,
        sortable_name:,
        roles:,
        password:
      }
    )
  end

  def assert_success(result)
    expect(result.success?).to be(true), result.errors.full_messages.join(", ")
  end
end
