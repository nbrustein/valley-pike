require "rails_helper"

RSpec.describe UnitsOfWork::PublishRideRequest do
  describe ".execute" do
    let(:executor) { create(:user) }
    let(:ride_request) { create(:draft_ride_request) }

    context "when the ride request can be published" do
      it "publishes the ride request", :aggregate_failures do
        result = act

        assert_success(result)
        reloaded = RideRequest.find(ride_request.id)
        expect(reloaded.type).to eq("RideRequest::Published")
        expect(reloaded.draft).to be(false)
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

    context "when the ride request is already published" do
      let(:ride_request) { create(:ride_request) }

      it "returns an error" do
        result = act

        expect(result.success?).to be(false)
        expect(result.errors.full_messages).to include("Ride request is already published")
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
