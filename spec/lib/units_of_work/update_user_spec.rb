require "rails_helper"

RSpec.describe UnitsOfWork::UpdateUser do
  describe ".execute" do
    let(:executor) { create(:user) }
    let(:organization) { create(:organization, abbreviation: "UDO") }
    let(:email) { "existing.user@example.com" }
    let(:user) { create(:user, email:) }
    let(:full_name) { "Updated User" }
    let(:preferred_name) { "Updated" }
    let(:phone) { "555-1212" }
    let(:driver_qualifications) { [ DriverQualification::QUALIFICATION_CWS_VETTED ] }
    let(:user_roles) do
      [
        {role: UserRole::ORG_ADMIN, organization_id: organization.id},
        {role: UserRole::DRIVER, organization_id: nil},
      ]
    end
    let(:password) { "An0therStr0ngPass!" }

    before do
      user.human.update!(
        full_name: "Old Name",
        preferred_name: "Old",
        phone: "555-0000"
      )
      create(:user_role, user:, role: UserRole::ORG_ADMIN, organization:)
      create(:user_role, user:, role: UserRole::VANITA_ADMIN)
    end

    it "updates the user fields" do
      result = act

      assert_success(result)

      user.reload
      expect(user.human.full_name).to eq(full_name)
      expect(user.human.preferred_name).to eq(preferred_name)
      expect(user.human.phone).to eq(phone)
      expect(user.user_roles.pluck(:role, :organization_id)).to contain_exactly(
        [ UserRole::ORG_ADMIN, organization.id ],
        [ UserRole::DRIVER, nil ]
      )
      expect(user.driver_qualifications.pluck(:qualification))
        .to contain_exactly(DriverQualification::QUALIFICATION_CWS_VETTED)
      identity = user.identities.find_by(kind: "password")
      expect(identity).to be_present
      expect(identity.email).to eq(email)
      expect(identity.valid_password?(password)).to be(true)
    end

    context "when a user role already exists" do
      it "does not replace the existing role" do
        existing_role = user.user_roles.find_by(role: UserRole::ORG_ADMIN, organization:)

        result = act

        assert_success(result)
        refreshed_role = user.reload.user_roles.find_by(role: UserRole::ORG_ADMIN, organization:)
        expect(refreshed_role.id).to eq(existing_role.id)
      end
    end

    context "when an existing user_role does not exist in the params" do
      let(:user_roles) { [ {role: UserRole::DRIVER, organization_id: nil} ] }

      it "destroys the user_role" do
        result = act

        assert_success(result)
        expect(user.reload.user_roles.pluck(:role, :organization_id))
          .to contain_exactly([ UserRole::DRIVER, nil ])
      end
    end

    context "when driver qualifications are removed" do
      let(:driver_qualifications) { [] }

      before do
        DriverQualification.create!(
          user:,
          qualification: DriverQualification::QUALIFICATION_CWS_VETTED
        )
      end

      it "clears the qualifications" do
        result = act

        assert_success(result)
        expect(user.reload.driver_qualifications).to be_empty
      end
    end

    context "when not all params are provided" do
      let(:custom_params) do
        {
          id: user.id,
          full_name: "Only Name",
        }
      end

      it "updates only provided fields" do
        result = act_with_params(custom_params)

        assert_success(result)
        user.reload
        expect(user.human.full_name).to eq("Only Name")
        expect(user.human.preferred_name).to eq("Old")
        expect(user.human.phone).to eq("555-0000")
      end
    end

    context "when assignment validation fails" do
      let(:validator) { instance_double(RideRequestAssignmentValidator) }

      before do
        allow(RideRequestAssignmentValidator).to receive(:new).and_return(validator)
        allow(validator).to receive(:validate).and_return(false)
        allow(validator).to receive(:errors).and_return(
          ActiveModel::Errors.new(validator).tap {|e| e.add(:base, "Validator error") }
        )
      end

      it "surfaces the validator errors and does not persist changes" do
        result = act

        expect(result.success?).to be(false)
        expect(result.errors.full_messages).to include("Validator error")
      end
    end

    context "when a nil value is passed" do
      let(:custom_params) do
        {
          id: user.id,
          phone: nil,
        }
      end

      it "sets the target attr to nil" do
        result = act_with_params(custom_params)

        assert_success(result)
        expect(user.reload.human.phone).to be_nil
      end
    end
  end

  private

  def act
    act_with_params(
      {
        id: user.id,
        full_name:,
        preferred_name:,
        phone:,
        user_roles:,
        driver_qualifications:,
        password:,
      }
    )
  end

  def act_with_params(params)
    described_class.execute(
      executor_id: executor.id,
      params:
    )
  end

  def assert_success(result)
    expect(result.success?).to be(true), result.errors.full_messages.join(", ")
  end
end
