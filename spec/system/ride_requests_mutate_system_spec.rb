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
      within_fieldset("Destination Address") do
        fill_in "Name", with: "City Hospital"
        fill_in "Street Address", with: "200 Broad St"
        fill_in "City", with: "Richmond"
        fill_in "State", with: "VA"
      end
      find("textarea[name='ride_request[ride_description_public]']").fill_in with: description
      click_button "Save and Continue"
    end

    it "saves the description and moves to page 3", :aggregate_failures do
      act
      expect(page).to have_current_path(%r{/ride_requests/[^/]+/edit/3})
      draft.reload
      expect(draft.ride_description_public).to eq(description)
      expect(draft.destination_address).to be_present
      expect(draft.destination_address.street_address).to eq("200 Broad St")
    end
  end

  context "when filling in page 3" do
    let(:draft) { create(:draft_ride_request, requester: identity.user, organization:) }

    def act
      visit edit_ride_request_path(id: draft.id, page: 3)
      fill_in "Name", with: "City Hospital"
      fill_in "Street Address", with: "100 Main St"
      fill_in "City", with: "Richmond"
      fill_in "State", with: "VA"
      find("textarea[name='ride_request[ride_description_private]']").fill_in with: "Ring the doorbell twice."
      click_button "Save and Continue"
    end

    it "saves the address and private notes and moves to page 4", :aggregate_failures do
      act
      expect(page).to have_current_path(%r{/ride_requests/[^/]+/edit/4})
      draft.reload
      expect(draft.pick_up_address).to be_present
      expect(draft.pick_up_address.street_address).to eq("100 Main St")
      expect(draft.pick_up_address.city).to eq("Richmond")
      expect(draft.pick_up_address.country).to eq("US")
      expect(draft.ride_description_private).to eq("Ring the doorbell twice.")
    end
  end

  context "when filling in page 4" do
    let(:draft) { create(:draft_ride_request, requester: identity.user, organization:) }

    def act
      visit edit_ride_request_path(id: draft.id, page: 4)
      fill_in "Contact Name", with: "Jane Doe"
      fill_in "Contact Phone", with: "555-9999"
      fill_in "Contact Email", with: "jane@example.com"
      click_button "Save and Continue"
    end

    it "saves the contact info and moves to page 5", :aggregate_failures do
      act
      expect(page).to have_current_path(%r{/ride_requests/[^/]+/edit/5})
      draft.reload
      expect(draft.contact_full_name).to eq("Jane Doe")
      expect(draft.contact_phone).to eq("555-9999")
      expect(draft.contact_email).to eq("jane@example.com")
    end

    it "defaults fields from the requester", :aggregate_failures do
      no_contact_draft = create(:draft_ride_request,
        requester: identity.user, organization:,
        contact_full_name: nil, contact_phone: nil, contact_email: nil)
      visit edit_ride_request_path(id: no_contact_draft.id, page: 4)
      requester = identity.user
      expect(find_field("Contact Name").value).to eq(requester.human.full_name)
      expect(find_field("Contact Phone").value).to eq(requester.human.phone)
      expect(find_field("Contact Email").value).to eq(requester.email)
    end
  end

  context "when publishing from page 5" do
    let(:draft) { create(:draft_ride_request, requester: identity.user, organization:) }

    it "publishes the ride request and redirects to index", :aggregate_failures do
      visit edit_ride_request_path(id: draft.id, page: 5)
      click_button "Publish"
      expect(page).to have_current_path(ride_requests_path)
      expect(RideRequest.find(draft.id)).to be_a(RideRequest::Published)
    end

    it "shows errors when publishing fails" do
      unpublishable = create(:draft_ride_request,
        requester: identity.user, organization:,
        contact_full_name: nil, ride_description_public: nil)
      visit edit_ride_request_path(id: unpublishable.id, page: 5)
      click_button "Publish"
      expect(page).to have_text("can't be blank")
    end
  end
end
