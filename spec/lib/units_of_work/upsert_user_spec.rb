require "rails_helper"

RSpec.describe UnitsOfWork::UpsertUser do
  describe ".execute" do
    let(:executor) { create(:user) }
    let(:organization) { create(:organization, abbreviation: "UDO") }
    let(:email) { "existing.user@example.com" }
    let(:full_name) { "Existing User" }
    let(:preferred_name) { "Existing" }
    let(:phone) { "555-9898" }
    let(:user_roles) do
      [
        {role: UserRole::ORG_ADMIN, organization_id: organization.id},
      ]
    end
    let(:driver_qualifications) { [] }
    let(:password) { nil }

    context "when the user does not exist" do
      it "creates the user" do
        result = act

        assert_success(result)
        user = User.find_by(email:)

        expect(user).to be_present
        expect(user.human.full_name).to eq(full_name)
      end
    end

    context "when the user already exists" do
      let!(:user) { create(:user, email:) }

      before do
        user.human.update!(
          full_name: "Old Name",
          preferred_name: "Old",
          phone: "555-0000"
        )
      end

      it "updates user" do
        result = act

        assert_success(result)

        user.reload
        expect(user.human.full_name).to eq(full_name)
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
        preferred_name:,
        phone:,
        user_roles:,
        driver_qualifications:,
        password:,
      }
    )
  end

  def assert_success(result)
    expect(result.success?).to be(true), result.errors.full_messages.join(", ")
  end
end
