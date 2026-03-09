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
      fill_in_date "Ride Date", with: date
      choose "Multiple Drivers"
      choose "Female Driver"
      fill_in "Appointment Time", with: appointment_time
      click_button "Save and Continue"
    end

    context "when submitted values are invalid" do
      it "shows errors" do
        visit new_ride_request_path
        fill_in "Short Description", with: "Hospital appointment"
        fill_in_date "Ride Date", with: Date.today - 1
        fill_in "Appointment Time", with: "10:00 AM"
        click_button "Save and Continue"
        expect(page).to have_text("Date must not be in the past")
      end
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

  context "when filling in page 2" do
    let(:draft) { create(:draft_ride_request, requester: identity.user, organization:) }
    let(:description) { "We are looking for a ride for a woman to a medical appointment." }

    def act
      visit edit_ride_request_path(id: draft.id, page: 2)
      find("textarea[name='ride_request[ride_description_public]']").fill_in with: description
      click_button "Save and Continue"
    end

    it "saves the description and moves to page 3", :aggregate_failures do
      act
      expect(page).to have_current_path(%r{/ride_requests/[^/]+/edit/3})
      expect(draft.reload.ride_description_public).to eq(description)
    end
  end
end
