require "rails_helper"

RSpec.describe DriverAssignment do
  describe "validations" do
    it "prevents changing ride_request_id on update" do
      assignment = create(:driver_assignment)
      other_ride_request = create(:ride_request)

      assignment.ride_request = other_ride_request

      expect(assignment).not_to be_valid
      expect(assignment.errors[:ride_request]).to include("cannot be changed")
    end

    it "allows saving without changing ride_request_id" do
      assignment = create(:driver_assignment)

      assignment.canceled = true

      expect(assignment).to be_valid
    end

    it "prevents destruction" do
      assignment = create(:driver_assignment)

      expect(assignment.destroy).to be(false)
      expect(assignment.errors[:base]).to include("Driver assignments cannot be destroyed")
      expect(DriverAssignment.find_by(id: assignment.id)).to be_present
    end
  end
end
