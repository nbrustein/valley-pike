require "rails_helper"

RSpec.describe UnitsOfWork::AcceptRideRequest do
  describe ".execute" do
    let(:driver) { create(:user, role: UserRole::DRIVER) }
    let(:ride_request) { create(:ride_request) }

    it "creates a driver assignment" do
      result = act

      assert_success(result)
      expect(ride_request.driver_assignments.find_by(driver:)).to be_present
    end

    context "when the ride request is not found" do
      it "returns an error" do
        result = described_class.execute(
          executor_id: driver.id,
          params: {ride_request_id: SecureRandom.uuid},
        )

        expect(result.success?).to be(false)
        expect(result.errors.full_messages).to include("Ride request not found")
      end
    end

    context "when the ride request is a draft" do
      let(:ride_request) { create(:draft_ride_request) }

      it "returns an error" do
        result = act

        expect(result.success?).to be(false)
        expect(result.errors.full_messages.first).to include("draft")
      end
    end

    context "when the driver is already assigned" do
      before { create(:driver_assignment, ride_request:, driver:) }

      it "returns an error" do
        result = act

        expect(result.success?).to be(false)
      end
    end
  end

  private

  def act
    described_class.execute(
      executor_id: driver.id,
      params: {ride_request_id: ride_request.id},
    )
  end

  def assert_success(result)
    expect(result.success?).to be(true), result.errors.full_messages.join(", ")
  end
end
