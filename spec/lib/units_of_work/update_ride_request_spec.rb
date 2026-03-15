require "rails_helper"

RSpec.describe UnitsOfWork::UpdateRideRequest do
  describe ".execute" do
    let(:executor) { create(:user) }
    let(:ride_request) { create(:ride_request) }

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
        result = act(short_description: "Updated description")

        expect(result.success?).to be(false)
        expect(result.errors.full_messages).to include("Validator error")
        expect(ride_request.reload.short_description).not_to eq("Updated description")
      end
    end
  end

  private

  def act(attrs={})
    described_class.execute(
      executor_id: executor.id,
      params: {id: ride_request.id}.merge(attrs)
    )
  end
end
