require "rails_helper"

RSpec.describe DriverRideRequestShowComponent, type: :component do
  let(:organization) { build_stubbed(:organization, name: "Test Org") }
  let(:pick_up_address) do
    build_stubbed(:address, name: "Home", street_address: "123 Main St", city: "Richmond", state: "VA", zip: "23220")
  end
  let(:destination_address) do
    build_stubbed(:address, name: "Hospital", street_address: "456 Oak Ave",
      city: "Richmond", state: "VA", zip: "23221")
  end
  let(:ride_request) do
    build_stubbed(:ride_request,
      organization:,
      pick_up_address:,
      destination_address:,
      short_description: "Doctor appointment",
      date: Date.new(2026, 6, 15),
      appointment_time: "2:00 PM",
      ride_description_public: "Please arrive 10 minutes early.",
      driver_notes: "Park in the back lot.",
      contact_full_name: "Jane Doe",
      contact_phone: "555-1234",
      contact_email: "jane@example.com",
      desired_driver_gender: "female")
  end

  def render_component
    render_inline(described_class.new(ride_request:))
  end

  it "renders the short description as the title" do
    render_component
    expect(page).to have_css("h1", text: "Doctor appointment")
  end

  it "renders the organization name" do
    render_component
    expect(page).to have_text("Test Org")
  end

  it "renders the formatted date" do
    render_component
    expect(page).to have_text("June 15, 2026")
  end

  it "renders the appointment time" do
    render_component
    expect(page).to have_text("2:00 PM")
  end

  it "renders the status" do
    render_component
    expect(page).to have_text("Request Sent")
  end

  it "renders the gender preference" do
    render_component
    expect(page).to have_text("Female driver requested")
  end

  it "renders the pick up address" do
    render_component
    expect(page).to have_text("Home")
    expect(page).to have_text("123 Main St, Richmond, VA, 23220")
  end

  it "renders the destination address" do
    render_component
    expect(page).to have_text("Hospital")
    expect(page).to have_text("456 Oak Ave, Richmond, VA, 23221")
  end

  it "renders the ride description" do
    render_component
    expect(page).to have_text("Please arrive 10 minutes early.")
  end

  it "renders the driver notes" do
    render_component
    expect(page).to have_text("Park in the back lot.")
  end

  it "renders the contact info" do
    render_component
    expect(page).to have_text("Jane Doe")
    expect(page).to have_text("555-1234")
    expect(page).to have_text("jane@example.com")
  end

  it "renders a back link" do
    render_component
    expect(page).to have_link("Back", href: "/")
  end

  context "when optional fields are absent" do
    let(:ride_request) do
      build_stubbed(:ride_request,
        organization:,
        pick_up_address:,
        destination_address: nil,
        short_description: "Simple ride",
        date: Date.new(2026, 6, 15),
        appointment_time: nil,
        ride_description_public: "Description",
        driver_notes: nil,
        contact_full_name: "Jane",
        contact_phone: nil,
        contact_email: nil,
        desired_driver_gender: "none")
    end

    it "hides the destination address section" do
      render_component
      expect(page).not_to have_text("Destination")
    end

    it "hides the appointment time" do
      render_component
      expect(page).not_to have_text("Appointment Time")
    end

    it "hides the driver notes section" do
      render_component
      expect(page).not_to have_text("Driver Notes")
    end

    it "hides the gender preference when none" do
      render_component
      expect(page).not_to have_text("Driver Preference")
    end
  end
end
