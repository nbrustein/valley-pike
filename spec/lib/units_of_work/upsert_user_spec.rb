require "rails_helper"

RSpec.describe UnitsOfWork::UpsertUser do
  describe ".execute" do
    let(:executor) { create(:user) }
    let(:organization) { create(:organization, abbreviation: "UDO") }
    let(:other_organization) { create(:organization, abbreviation: "VDO") }
    let(:email) { "existing.user@example.com" }
    let(:full_name) { "Existing User" }
    let(:phone) { "555-9898" }
    let(:sortable_name) { "User" }
    let(:roles) do
      [
        {role: UserRole::ORG_ADMIN, organization_id: organization.id},
        {role: UserRole::DRIVER, organization_id: nil},
      ]
    end
    let(:password) { nil }

    context "when the user does not exist" do
      it "creates the user" do
        result = act

        assert_success(result)
        user = User.find_by(email:)

        expect(user).to be_present
        expect(user.human.full_name).to eq(full_name)
        expect(user.user_roles.pluck(:role, :organization_id)).to contain_exactly(
          [ UserRole::ORG_ADMIN, organization.id ],
          [ UserRole::DRIVER, nil ]
        )
      end
    end

    context "when the user already exists" do
      let!(:user) { create(:user, email:) }

      before do
        user.human.update!(full_name: "Old Name", phone: "555-0000", sortable_name: "Old")
        create(:user_role, user:, role: UserRole::VANITA_ADMIN)
        create(:user_role, user:, role: UserRole::ORG_ADMIN, organization: other_organization)
      end

      it "updates the human and syncs roles" do
        result = act

        assert_success(result)

        user.reload
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

        it "upserts a password identity" do
          result = act

          assert_success(result)
          identity = user.reload.identities.find_by(kind: "password")

          expect(identity).to be_present
          expect(identity.email).to eq(email)
          expect(identity.valid_password?(password)).to be(true)
        end
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
        password:,
      }
    )
  end

  def assert_success(result)
    expect(result.success?).to be(true), result.errors.full_messages.join(", ")
  end
end
