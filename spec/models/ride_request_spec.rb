require "rails_helper"

RSpec.describe RideRequest, type: :model do
  describe "date validation" do
    let(:ride_request) { build(:draft_ride_request, date: Date.today) }

    it "is valid when date is today" do
      expect(ride_request).to be_valid
    end

    it "is valid when date is in the future" do
      ride_request.date = Date.today + 1
      expect(ride_request).to be_valid
    end

    it "is invalid when created with a past date" do
      new_rr = build(:draft_ride_request, date: Date.today - 1)
      expect(new_rr).not_to be_valid
      expect(new_rr.errors[:date]).to include("must not be in the past")
    end

    it "is invalid when date is changed to a past date" do
      ride_request.date = Date.today - 1
      expect(ride_request).not_to be_valid
      expect(ride_request.errors[:date]).to include("must not be in the past")
    end

    it "is valid when date is already in the past and not changed" do
      ride_request.save!
      ride_request.update_column(:date, Date.today - 1)
      ride_request.reload
      ride_request.short_description = "Updated description"
      expect(ride_request).to be_valid
    end
  end
end
