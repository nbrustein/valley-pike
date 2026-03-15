require "rails_helper"

RSpec.describe DriverRideRequestsIndexComponent, type: :component do
  let(:organization) { build_stubbed(:organization, name: "Test Org") }
  let(:destination_address) { build_stubbed(:address, name: "City Hospital", city: "Richmond") }

  describe "title" do
    it "renders the title" do
      render_inline(described_class.new(ride_requests: []))
      expect(page).to have_css("h1", text: "Active Rides")
    end
  end

  describe "empty state" do
    it "shows a message when there are no ride requests" do
      render_inline(described_class.new(ride_requests: []))
      expect(page).to have_text("No ride requests available.")
    end
  end

  describe "ride request cards" do
    let(:ride_request) do
      build_stubbed(:ride_request,
        organization:,
        destination_address:,
        short_description: "Hospital visit",
        date: Date.new(2026, 6, 15))
    end

    it "renders the short description" do
      render_inline(described_class.new(ride_requests: [ ride_request ]))
      expect(page).to have_text("Hospital visit")
    end

    it "renders the organization name" do
      render_inline(described_class.new(ride_requests: [ ride_request ]))
      expect(page).to have_text("Test Org")
    end

    it "renders the date" do
      render_inline(described_class.new(ride_requests: [ ride_request ]))
      expect(page).to have_text("Jun 15, 2026")
    end

    it "renders the destination address" do
      render_inline(described_class.new(ride_requests: [ ride_request ]))
      expect(page).to have_text("City Hospital, Richmond")
    end

    context "when the ride request has no destination address" do
      let(:ride_request) do
        build_stubbed(:ride_request,
          organization:,
          destination_address: nil,
          short_description: "Ride",
          date: Date.new(2026, 6, 15))
      end

      it "does not render the destination" do
        render_inline(described_class.new(ride_requests: [ ride_request ]))
        expect(page).not_to have_text("City Hospital")
      end
    end

    it "links each card to the driver ride request show page" do
      render_inline(described_class.new(ride_requests: [ ride_request ]))
      expect(page).to have_link(href: %r{/driver/ride_requests/#{ride_request.id}})
    end
  end
end
