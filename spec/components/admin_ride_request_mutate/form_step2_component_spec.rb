require "rails_helper"

RSpec.describe AdminRideRequestMutate::FormStep2Component, type: :component do
  def build_form(ride_request=nil)
    ActionView::Helpers::FormBuilder.new("ride_request", ride_request, vc_test_controller.view_context, {})
  end

  def render_component(ride_request: nil)
    render_inline(described_class.new(form: build_form(ride_request), total_steps: 5, ride_request:))
  end

  before do
    allow(Shared::AddressFieldsComponent).to receive(:new).and_call_original
    allow(Shared::TextareaFieldComponent).to receive(:new).and_call_original
  end

  describe "pick_up_address_field" do
    it "passes the correct arguments to AddressFieldsComponent" do
      render_component
      expect(Shared::AddressFieldsComponent).to have_received(:new).with(
        form: anything,
        field: :pick_up_address,
        label: "Pick Up Address",
        value: nil,
        street_address_description: "The exact street address will only be sent to the driver who accepts the ride",
      )
    end

    context "when a ride request with a pick_up_address is provided" do
      it "passes the address as value" do
        address = build_stubbed(:address)
        rr = build_stubbed(:draft_ride_request, pick_up_address: address)
        render_component(ride_request: rr)
        expect(Shared::AddressFieldsComponent).to have_received(:new).with(
          hash_including(field: :pick_up_address, value: address)
        )
      end
    end
  end

  describe "destination_address_field" do
    it "passes the correct arguments to AddressFieldsComponent" do
      render_component
      expect(Shared::AddressFieldsComponent).to have_received(:new).with(
        form: anything,
        field: :destination_address,
        label: "Destination Address",
        value: nil,
      )
    end

    context "when a ride request with a destination_address is provided" do
      it "passes the address as value" do
        address = build_stubbed(:address)
        rr = build_stubbed(:draft_ride_request, destination_address: address)
        render_component(ride_request: rr)
        expect(Shared::AddressFieldsComponent).to have_received(:new).with(
          hash_including(value: address)
        )
      end
    end
  end

  describe "ride_description_public_field" do
    it "passes the correct arguments to TextareaFieldComponent" do
      render_component
      expect(Shared::TextareaFieldComponent).to have_received(:new).with(
        form: anything,
        field: :ride_description_public,
        value: nil,
        placeholder: start_with("We are looking for a ride"),
        required: true,
        rows: 6,
      )
    end

    context "when there is a ride request" do
      it "passes ride_description_public as value" do
        rr = build_stubbed(:draft_ride_request, ride_description_public: "A ride to the doctor.")
        render_component(ride_request: rr)
        expect(Shared::TextareaFieldComponent).to have_received(:new).with(
          hash_including(value: "A ride to the doctor.")
        )
      end
    end

    context "when there is no ride request" do
      it "passes nil as value" do
        render_component
        expect(Shared::TextareaFieldComponent).to have_received(:new).with(hash_including(value: nil))
      end
    end
  end
end
