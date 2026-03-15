require "rails_helper"

RSpec.describe DriverRideRequestsIndexComponent, type: :component do
  let(:current_user) { build_stubbed(:user) }
  let(:organization) { build_stubbed(:organization, name: "Test Org") }
  let(:destination_address) { build_stubbed(:address, name: "City Hospital", city: "Richmond") }

  def build_ride(attrs={})
    defaults = {
      organization:,
      destination_address:,
      short_description: "Hospital visit",
      date: Date.current + 7,
      completed: false,
      cancelled: false,
      has_enough_drivers: false,
      driver_assignments: [],
    }
    build_stubbed(:ride_request, **defaults.merge(attrs))
  end

  def assignment_for(user, ride_request)
    build_stubbed(:driver_assignment, driver: user, ride_request:)
  end

  def render_component(ride_requests:)
    render_inline(described_class.new(ride_requests:, current_user:))
  end

  describe "empty state" do
    it "shows a message when there are no ride requests" do
      render_component(ride_requests: [])
      expect(page).to have_text("No ride requests available.")
    end
  end

  describe "sections" do
    it "renders Your Upcoming Rides for assigned future rides" do
      rr = build_ride(short_description: "My ride")
      allow(rr).to receive(:driver_assignments).and_return([ assignment_for(current_user, rr) ])

      render_component(ride_requests: [ rr ])

      expect(page).to have_css("h2", text: "Your Upcoming Rides")
      expect(page).to have_text("My ride")
    end

    it "renders Looking for Drivers for unassigned rides needing drivers" do
      rr = build_ride(short_description: "Needs a driver", has_enough_drivers: false)

      render_component(ride_requests: [ rr ])

      expect(page).to have_css("h2", text: "Looking for Drivers")
      expect(page).to have_text("Needs a driver")
    end

    it "renders No Longer Available for rides with enough drivers" do
      rr = build_ride(short_description: "Full ride", has_enough_drivers: true)

      render_component(ride_requests: [ rr ])

      expect(page).to have_css("h2", text: "No Longer Available")
      expect(page).to have_text("Full ride")
    end

    it "renders No Longer Available for cancelled rides" do
      rr = build_ride(short_description: "Cancelled ride", cancelled: true)

      render_component(ride_requests: [ rr ])

      expect(page).to have_css("h2", text: "No Longer Available")
      expect(page).to have_text("Cancelled ride")
    end

    it "renders Your Completed Rides for completed assigned rides" do
      rr = build_ride(short_description: "Done ride", completed: true)
      allow(rr).to receive(:driver_assignments).and_return([ assignment_for(current_user, rr) ])

      render_component(ride_requests: [ rr ])

      expect(page).to have_css("h2", text: "Your Completed Rides")
      expect(page).to have_text("Done ride")
    end

    it "renders Your Completed Rides for cancelled assigned rides" do
      rr = build_ride(short_description: "Cancelled assigned", cancelled: true)
      allow(rr).to receive(:driver_assignments).and_return([ assignment_for(current_user, rr) ])

      render_component(ride_requests: [ rr ])

      expect(page).to have_css("h2", text: "Your Completed Rides")
      expect(page).to have_text("Cancelled assigned")
    end

    it "hides other section headers when they have no rides" do
      rr = build_ride(short_description: "Available")

      render_component(ride_requests: [ rr ])

      expect(page).not_to have_css("h2", text: "Your Upcoming Rides")
      expect(page).not_to have_css("h2", text: "No Longer Available")
      expect(page).not_to have_css("h2", text: "Your Completed Rides")
    end

    it "shows 'All upcoming rides have drivers assigned.' when no rides need drivers but some are staffed" do
      rr = build_ride(has_enough_drivers: true)

      render_component(ride_requests: [ rr ])

      expect(page).to have_css("h2", text: "Looking for Drivers")
      expect(page).to have_text("All upcoming rides have drivers assigned.")
    end

    it "shows 'There are no upcoming rides.' when all unassigned rides are cancelled" do
      rr = build_ride(cancelled: true)

      render_component(ride_requests: [ rr ])

      expect(page).to have_css("h2", text: "Looking for Drivers")
      expect(page).to have_text("There are no upcoming rides.")
    end

    it "shows 'There are no upcoming rides.' when there are no unassigned rides at all" do
      rr = build_ride(completed: true)
      allow(rr).to receive(:driver_assignments).and_return([ assignment_for(current_user, rr) ])

      render_component(ride_requests: [ rr ])

      expect(page).to have_css("h2", text: "Looking for Drivers")
      expect(page).to have_text("There are no upcoming rides.")
    end
  end

  describe "ride request cards" do
    let(:ride_request) do
      build_ride(
        short_description: "Hospital visit",
        date: Date.new(2026, 6, 15),
      )
    end

    it "renders the short description" do
      render_component(ride_requests: [ ride_request ])
      expect(page).to have_text("Hospital visit")
    end

    it "renders the organization name" do
      render_component(ride_requests: [ ride_request ])
      expect(page).to have_text("Test Org")
    end

    it "renders the date" do
      render_component(ride_requests: [ ride_request ])
      expect(page).to have_text("Jun 15, 2026")
    end

    it "renders the destination address" do
      render_component(ride_requests: [ ride_request ])
      expect(page).to have_text("City Hospital, Richmond")
    end

    context "when the ride request has no destination address" do
      let(:ride_request) do
        build_ride(
          destination_address: nil,
          short_description: "Ride",
          date: Date.new(2026, 6, 15),
        )
      end

      it "does not render the destination" do
        render_component(ride_requests: [ ride_request ])
        expect(page).not_to have_text("City Hospital")
      end
    end

    it "links each card to the driver ride request show page" do
      render_component(ride_requests: [ ride_request ])
      expect(page).to have_link(href: %r{/driver/ride_requests/#{ride_request.id}})
    end
  end
end
