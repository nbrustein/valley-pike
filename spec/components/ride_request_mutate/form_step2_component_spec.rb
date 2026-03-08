require "rails_helper"

RSpec.describe RideRequestMutate::FormStep2Component, type: :component do
  def build_form(ride_request=nil)
    ActionView::Helpers::FormBuilder.new("ride_request", ride_request, vc_test_controller.view_context, {})
  end

  def render_component(ride_request: nil)
    render_inline(described_class.new(form: build_form(ride_request), ride_request:))
  end

  before do
    allow(Shared::TextareaFieldComponent).to receive(:new).and_call_original
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
        expect(Shared::TextareaFieldComponent).to have_received(:new).with(hash_including(value: "A ride to the doctor."))
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
