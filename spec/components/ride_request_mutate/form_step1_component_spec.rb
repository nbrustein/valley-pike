require "rails_helper"

RSpec.describe RideRequestMutate::FormStep1Component, type: :component do
  let(:organization) { build_stubbed(:organization) }
  let(:other_organization) { build_stubbed(:organization) }

  def build_form(ride_request=nil)
    ActionView::Helpers::FormBuilder.new("ride_request", ride_request, vc_test_controller.view_context, {})
  end

  def render_component(organizations: [ organization ], ride_request: nil)
    render_inline(described_class.new(form: build_form(ride_request), organizations:, ride_request:))
  end

  before do
    allow(Shared::SelectFieldComponent).to receive(:new).and_call_original
    allow(Shared::TextFieldComponent).to receive(:new).and_call_original
    allow(Shared::DateFieldComponent).to receive(:new).and_call_original
    allow(Shared::RadioGroupComponent).to receive(:new).and_call_original
  end

  describe "organization_field" do
    let(:organizations) { [ organization, other_organization ] }

    it "passes the correct arguments to SelectFieldComponent" do
      render_component(organizations:)
      expect(Shared::SelectFieldComponent).to have_received(:new).with(
        form: anything,
        field: :organization_id,
        label: "Organization",
        options: [ [ organization.name, organization.id ], [ other_organization.name, other_organization.id ] ],
        selected: nil
      )
    end

    context "when there is a ride request" do
      it "passes organization_id as selected" do
        rr = build_stubbed(:draft_ride_request, organization_id: organization.id)
        render_component(organizations:, ride_request: rr)
        expect(Shared::SelectFieldComponent).to have_received(:new).with(hash_including(selected: organization.id))
      end
    end

    context "when there is no ride request" do
      it "passes nil as selected" do
        render_component(organizations:)
        expect(Shared::SelectFieldComponent).to have_received(:new).with(hash_including(selected: nil))
      end
    end
  end

  describe "short_description_field" do
    it "passes the correct arguments to TextFieldComponent" do
      render_component
      expect(Shared::TextFieldComponent).to have_received(:new).with(hash_including(
        field: :short_description,
        label: "Short Description",
        description: start_with("Used as the email subject line")
      ))
    end

    context "when there is a ride request" do
      it "passes short_description as value" do
        rr = build_stubbed(:draft_ride_request, short_description: "Hospital run")
        render_component(ride_request: rr)
        expect(Shared::TextFieldComponent).to have_received(:new).with(hash_including(field: :short_description, value: "Hospital run"))
      end
    end

    context "when there is no ride request" do
      it "passes nil as value" do
        render_component
        expect(Shared::TextFieldComponent).to have_received(:new).with(hash_including(field: :short_description, value: nil))
      end
    end
  end

  describe "ride_date_field" do
    it "passes the correct arguments to DateFieldComponent" do
      render_component
      expect(Shared::DateFieldComponent).to have_received(:new).with(
        form: anything,
        field: :date,
        label: "Ride Date",
        value: nil
      )
    end

    context "when there is a ride request" do
      it "passes the iso8601 date as value" do
        rr = build_stubbed(:draft_ride_request, date: Date.new(2026, 6, 15))
        render_component(ride_request: rr)
        expect(Shared::DateFieldComponent).to have_received(:new).with(hash_including(value: "2026-06-15"))
      end
    end

    context "when there is no ride request" do
      it "passes nil as value" do
        render_component
        expect(Shared::DateFieldComponent).to have_received(:new).with(hash_including(value: nil))
      end
    end
  end

  describe "driver_count_field" do
    it "passes the correct arguments to RadioGroupComponent" do
      render_component
      expect(Shared::RadioGroupComponent).to have_received(:new).with(hash_including(
        name: "ride_request[requires_multiple_drivers]",
        label: "Number of Drivers",
        options: [ [ "false", "1 Driver" ], [ "true", "Multiple Drivers" ] ],
        include_none_option: false
      ))
    end

    context "when there is a ride request" do
      it "passes requires_multiple_drivers as selected" do
        rr = build_stubbed(:draft_ride_request, requires_multiple_drivers: true)
        render_component(ride_request: rr)
        expect(Shared::RadioGroupComponent).to have_received(:new).with(
          hash_including(name: "ride_request[requires_multiple_drivers]", selected: "true")
        )
      end
    end

    context "when there is no ride request" do
      it "defaults selected to false" do
        render_component
        expect(Shared::RadioGroupComponent).to have_received(:new).with(
          hash_including(name: "ride_request[requires_multiple_drivers]", selected: "false")
        )
      end
    end
  end

  describe "driver_gender_field" do
    it "passes the correct arguments to RadioGroupComponent" do
      render_component
      expect(Shared::RadioGroupComponent).to have_received(:new).with(hash_including(
        name: "ride_request[desired_driver_gender]",
        label: "Driver Gender Requirement",
        options: [
          [ "none", "None" ],
          [ "female", "Female Driver" ],
          [ "female_accompaniment", "Female Accompaniment if Driver is Male" ],
        ],
        include_none_option: false
      ))
    end

    context "when there is a ride request" do
      it "passes desired_driver_gender as selected" do
        rr = build_stubbed(:draft_ride_request, desired_driver_gender: "female")
        render_component(ride_request: rr)
        expect(Shared::RadioGroupComponent).to have_received(:new).with(
          hash_including(name: "ride_request[desired_driver_gender]", selected: "female")
        )
      end
    end

    context "when there is no ride request" do
      it "defaults selected to none" do
        render_component
        expect(Shared::RadioGroupComponent).to have_received(:new).with(
          hash_including(name: "ride_request[desired_driver_gender]", selected: "none")
        )
      end
    end
  end

  describe "appointment_time_field" do
    it "passes the correct arguments to TextFieldComponent" do
      render_component
      expect(Shared::TextFieldComponent).to have_received(:new).with(hash_including(
        field: :appointment_time,
        label: "Appointment / Timing",
        description: start_with("Enter a specific time")
      ))
    end

    context "when there is a ride request" do
      it "passes appointment_time as value" do
        rr = build_stubbed(:draft_ride_request, appointment_time: "10:00 AM")
        render_component(ride_request: rr)
        expect(Shared::TextFieldComponent).to have_received(:new).with(hash_including(field: :appointment_time, value: "10:00 AM"))
      end
    end

    context "when there is no ride request" do
      it "passes nil as value" do
        render_component
        expect(Shared::TextFieldComponent).to have_received(:new).with(hash_including(field: :appointment_time, value: nil))
      end
    end
  end
end
