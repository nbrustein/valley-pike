require "rails_helper"

RSpec.describe UnitsOfWork::DeleteDraftRideRequest do
  describe ".execute" do
    let(:executor) { create(:user) }
    let(:ride_request) { create(:draft_ride_request) }

    context "when the ride request is a draft" do
      it "deletes the ride request" do
        result = act

        assert_success(result)
        expect(RideRequest.find_by(id: ride_request.id)).to be_nil
      end
    end

    context "when the ride request does not exist" do
      let(:ride_request) { double(id: SecureRandom.uuid) }

      it "returns an error" do
        result = act

        expect(result.success?).to be(false)
        expect(result.errors.full_messages).to include("Ride request not found")
      end
    end

    context "when the ride request is published" do
      let(:ride_request) { create(:ride_request) }

      it "returns an error" do
        result = act

        expect(result.success?).to be(false)
        expect(RideRequest.find_by(id: ride_request.id)).to be_present
      end
    end
  end

  private

  def act
    described_class.execute(
      executor_id: executor.id,
      params: {ride_request_id: ride_request.id}
    )
  end

  def assert_success(result)
    expect(result.success?).to be(true), result.errors.full_messages.join(", ")
  end
end
