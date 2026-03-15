require "rails_helper"

RSpec.describe UnitsOfWork::UpdateOrganization do
  describe ".execute" do
    let(:executor) { create(:user) }
    let(:organization) { create(:organization, name: "Old Name", abbreviation: "OLD", required_qualifications: []) }

    it "updates the organization fields" do
      result = act(name: "New Name", abbreviation: "NEW")

      assert_success(result)
      organization.reload
      expect(organization.name).to eq("New Name")
      expect(organization.abbreviation).to eq("NEW")
    end

    it "updates only provided fields" do
      result = act(name: "New Name")

      assert_success(result)
      organization.reload
      expect(organization.name).to eq("New Name")
      expect(organization.abbreviation).to eq("OLD")
    end

    it "updates required_qualifications" do
      result = act(required_qualifications: [ DriverQualification::QUALIFICATION_CWS_VETTED ])

      assert_success(result)
      expect(organization.reload.required_qualifications)
        .to eq([ DriverQualification::QUALIFICATION_CWS_VETTED ])
    end

    it "deduplicates and strips blanks from required_qualifications" do
      result = act(required_qualifications: [
        DriverQualification::QUALIFICATION_CWS_VETTED,
        "",
        DriverQualification::QUALIFICATION_CWS_VETTED,
      ])

      assert_success(result)
      expect(organization.reload.required_qualifications)
        .to eq([ DriverQualification::QUALIFICATION_CWS_VETTED ])
    end

    context "when organization is not found" do
      it "returns an error" do
        result = described_class.execute(
          executor_id: executor.id,
          params: {id: SecureRandom.uuid},
        )

        expect(result.success?).to be(false)
        expect(result.errors.full_messages).to include("Organization not found")
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
        result = act(required_qualifications: [ DriverQualification::QUALIFICATION_CWS_VETTED ])

        expect(result.success?).to be(false)
        expect(result.errors.full_messages).to include("Validator error")
        expect(organization.reload.required_qualifications).to eq([])
      end
    end
  end

  private

  def act(attrs={})
    described_class.execute(
      executor_id: executor.id,
      params: {id: organization.id}.merge(attrs),
    )
  end

  def assert_success(result)
    expect(result.success?).to be(true), result.errors.full_messages.join(", ")
  end
end
