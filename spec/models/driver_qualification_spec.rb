require "rails_helper"

RSpec.describe DriverQualification do
  describe "validations" do
    let(:user) { create(:user) }

    context "when qualification is valid" do
      it "is valid" do
        record = described_class.new(user:, qualification: described_class::QUALIFICATION_CWS_VETTED)

        expect(record).to be_valid
      end
    end

    context "when qualification is invalid" do
      it "is invalid" do
        record = described_class.new(user:, qualification: "unknown")

        record.valid?

        expect(record.errors[:qualification]).to include("is not included in the list")
      end
    end

    context "when qualification is duplicated for the same user" do
      it "is invalid" do
        described_class.create!(user:, qualification: described_class::QUALIFICATION_CWS_VETTED)
        record = described_class.new(user:, qualification: described_class::QUALIFICATION_CWS_VETTED)

        record.valid?

        expect(record.errors[:qualification]).to include("has already been taken")
      end
    end
  end
end
