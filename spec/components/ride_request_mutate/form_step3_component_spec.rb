require "rails_helper"

RSpec.describe RideRequestMutate::FormStep3Component, type: :component do
  def build_form(ride_request=nil)
    ActionView::Helpers::FormBuilder.new("ride_request", ride_request, vc_test_controller.view_context, {})
  end

  def render_component(ride_request: nil)
    render_inline(described_class.new(form: build_form(ride_request), ride_request:))
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
      )
    end

    context "when a ride request with a pick_up_address is provided" do
      it "passes the address as value" do
        address = build_stubbed(:address)
        rr = build_stubbed(:draft_ride_request, pick_up_address: address)
        render_component(ride_request: rr)
        expect(Shared::AddressFieldsComponent).to have_received(:new).with(
          hash_including(value: address)
        )
      end
    end
  end

  describe "ride_description_private_field" do
    it "passes the correct arguments to TextareaFieldComponent" do
      render_component
      expect(Shared::TextareaFieldComponent).to have_received(:new).with(
        form: anything,
        field: :ride_description_private,
        value: nil,
        rows: 4,
      )
    end

    context "when a ride request with ride_description_private is provided" do
      it "passes ride_description_private as value" do
        rr = build_stubbed(:draft_ride_request, ride_description_private: "Ring the doorbell twice.")
        render_component(ride_request: rr)
        expect(Shared::TextareaFieldComponent).to have_received(:new).with(
          hash_including(value: "Ring the doorbell twice.")
        )
      end
    end
  end
end
