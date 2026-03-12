require "rails_helper"

RSpec.describe RideRequestMutate::FormStep5Component, type: :component do
  let(:organization) { build_stubbed(:organization) }

  def build_form(ride_request=nil)
    ActionView::Helpers::FormBuilder.new("ride_request", ride_request, vc_test_controller.view_context, {})
  end

  def render_component(ride_request: nil)
    render_inline(described_class.new(form: build_form(ride_request), total_steps: 5, ride_request:))
  end

  before do
    allow(Shared::TextFieldComponent).to receive(:new).and_call_original
    allow(Shared::TextareaFieldComponent).to receive(:new).and_call_original
    allow(Shared::DateFieldComponent).to receive(:new).and_call_original
    allow(Shared::RadioGroupComponent).to receive(:new).and_call_original
  end

  describe "public fields" do
    it "renders short_description_field as readonly" do
      render_component
      expect(Shared::TextFieldComponent).to have_received(:new).with(
        hash_including(field: :short_description, label: "Short Description", readonly: true)
      )
    end

    it "renders ride_date_field as readonly" do
      render_component
      expect(Shared::DateFieldComponent).to have_received(:new).with(
        hash_including(field: :date, label: "Ride Date", readonly: true)
      )
    end

    it "renders driver_count_field as readonly" do
      render_component
      expect(Shared::RadioGroupComponent).to have_received(:new).with(
        hash_including(label: "How many drivers do you need?", readonly: true)
      )
    end

    it "renders driver_gender_field as readonly" do
      render_component
      expect(Shared::RadioGroupComponent).to have_received(:new).with(
        hash_including(label: "Driver Gender Requirement", readonly: true)
      )
    end

    it "renders appointment_time_field as readonly" do
      render_component
      expect(Shared::TextFieldComponent).to have_received(:new).with(
        hash_including(field: :appointment_time, label: "Appointment Time", readonly: true)
      )
    end

    it "renders ride_description_public_field as readonly" do
      render_component
      expect(Shared::TextareaFieldComponent).to have_received(:new).with(
        hash_including(field: :ride_description_public, label: "Public Description", readonly: true)
      )
    end

    it "renders contact_full_name_field as readonly" do
      render_component
      expect(Shared::TextFieldComponent).to have_received(:new).with(
        hash_including(field: :contact_full_name, label: "Contact Name", readonly: true)
      )
    end

    it "renders contact_phone_field as readonly" do
      render_component
      expect(Shared::TextFieldComponent).to have_received(:new).with(
        hash_including(field: :contact_phone, label: "Contact Phone", readonly: true)
      )
    end

    it "renders contact_email_field as readonly" do
      render_component
      expect(Shared::TextFieldComponent).to have_received(:new).with(
        hash_including(field: :contact_email, label: "Contact Email", readonly: true)
      )
    end
  end

  describe "private fields" do
    it "renders ride_description_private_field as readonly" do
      render_component
      expect(Shared::TextareaFieldComponent).to have_received(:new).with(
        hash_including(field: :ride_description_private, label: "Private Ride Notes", readonly: true)
      )
    end
  end

  describe "values from ride request" do
    it "passes ride request values to all fields" do
      rr = build_stubbed(:ride_request, organization:,
        short_description: "Hospital visit",
        appointment_time: "9:00am",
        ride_description_public: "Ride for a woman",
        ride_description_private: "Ring doorbell",
        contact_full_name: "Jane Doe",
        contact_phone: "555-1234",
        contact_email: "jane@example.com")
      render_component(ride_request: rr)

      expect(Shared::TextFieldComponent).to have_received(:new).with(
        hash_including(field: :short_description, value: "Hospital visit")
      )
      expect(Shared::TextFieldComponent).to have_received(:new).with(
        hash_including(field: :appointment_time, value: "9:00am")
      )
      expect(Shared::TextareaFieldComponent).to have_received(:new).with(
        hash_including(field: :ride_description_public, value: "Ride for a woman")
      )
      expect(Shared::TextareaFieldComponent).to have_received(:new).with(
        hash_including(field: :ride_description_private, value: "Ring doorbell")
      )
      expect(Shared::TextFieldComponent).to have_received(:new).with(
        hash_including(field: :contact_full_name, value: "Jane Doe")
      )
      expect(Shared::TextFieldComponent).to have_received(:new).with(
        hash_including(field: :contact_phone, value: "555-1234")
      )
      expect(Shared::TextFieldComponent).to have_received(:new).with(
        hash_including(field: :contact_email, value: "jane@example.com")
      )
    end
  end
end
