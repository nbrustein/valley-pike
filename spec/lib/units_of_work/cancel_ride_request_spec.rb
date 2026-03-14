require "rails_helper"

RSpec.describe UnitsOfWork::CancelRideRequest do
  describe ".execute" do
    let(:executor) { create(:user) }
    let(:ride_request) { create(:ride_request) }

    context "when the ride request is published and active" do
      it "cancels the ride request", :aggregate_failures do
        result = act

        assert_success(result)
        expect(ride_request.reload.cancelled).to be(true)
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

    context "when the ride request is a draft" do
      let(:ride_request) { create(:draft_ride_request) }

      it "returns an error", :aggregate_failures do
        result = act

        expect(result.success?).to be(false)
        expect(ride_request.reload.cancelled).to be(false)
      end
    end

    context "when the ride request is already cancelled" do
      let(:ride_request) { create(:ride_request, cancelled: true) }

      it "succeeds idempotently" do
        result = act

        assert_success(result)
      end
    end

    context "when the ride request is completed" do
      let(:ride_request) { create(:ride_request, completed: true) }

      it "returns an error", :aggregate_failures do
        result = act

        expect(result.success?).to be(false)
        expect(ride_request.reload.cancelled).to be(false)
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
