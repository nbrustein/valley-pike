require "rails_helper"
require "warden/test/helpers"

RSpec.describe "Ride request create form", type: :system do
  include Warden::Test::Helpers

  let(:organization) { create(:organization) }
  let(:identity) do
    user = create(
      :user,
      :with_identity,
      email: "requester@example.com",
      role: UserRole::RIDE_REQUESTER,
      role_organization: organization,
      identity_kind: "magic_link",
      identity_email: "requester@example.com"
    )
    user.identities.find_by!(kind: "magic_link")
  end

  before { login_as(identity, scope: :identity) }

  after { Warden.test_reset! }

  context "when filling in page 1" do
    let(:short_description) { "Hospital appointment" }
    let(:date) { Date.new(2026, 6, 15) }
    let(:appointment_time) { "10:00 AM" }

    def act
      visit new_ride_request_path
      fill_in "Short Description", with: short_description
      execute_script("document.getElementById('ride_request_date').value = '#{date}'")
      choose "Multiple Drivers"
      choose "Female Driver"
      fill_in "Appointment / Timing", with: appointment_time
      click_button "Save and Continue"
    end

    it "creates a draft and moves to page 2", :aggregate_failures do
      act

      # Wait for Turbo navigation to complete before querying the DB
      expect(page).to have_current_path(%r{/ride_requests/[^/]+/edit/2})

      draft = RideRequest::Draft.order(created_at: :desc).first
      expect(draft).to be_present
      expect(draft.short_description).to eq(short_description)
      expect(draft.date).to eq(date)
      expect(draft.requires_multiple_drivers).to be(true)
      expect(draft.desired_driver_gender).to eq("female")
      expect(draft.appointment_time).to eq(appointment_time)
      expect(draft.organization_id).to eq(organization.id)
    end
  end
end
