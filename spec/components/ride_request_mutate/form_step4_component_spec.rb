require "rails_helper"

RSpec.describe RideRequestMutate::FormStep4Component, type: :component do
  def build_form(ride_request=nil)
    ActionView::Helpers::FormBuilder.new("ride_request", ride_request, vc_test_controller.view_context, {})
  end

  def render_component(ride_request: nil, requester: nil)
    render_inline(described_class.new(form: build_form(ride_request), total_steps: 5, ride_request:, requester:))
  end

  before do
    allow(Shared::ContactFieldsComponent).to receive(:new).and_call_original
  end

  describe "contact_fields" do
    it "passes the correct arguments" do
      render_component
      expect(Shared::ContactFieldsComponent).to have_received(:new).with(
        form: anything,
        label: "Contact",
        full_name: nil,
        phone: nil,
        email: nil,
        required_name: true,
      )
    end

    context "when a ride request with contact info is provided" do
      it "passes the ride request values" do
        rr = build_stubbed(:draft_ride_request,
          contact_full_name: "Alice Smith",
          contact_phone: "555-1234",
          contact_email: "alice@example.com")
        render_component(ride_request: rr)
        expect(Shared::ContactFieldsComponent).to have_received(:new).with(
          hash_including(
            full_name: "Alice Smith",
            phone: "555-1234",
            email: "alice@example.com",
          )
        )
      end
    end

    context "when no ride request value but requester is provided" do
      it "defaults to requester's info" do
        requester = build(:user)
        render_component(requester:)
        expect(Shared::ContactFieldsComponent).to have_received(:new).with(
          hash_including(
            full_name: requester.human.full_name,
            phone: requester.human.phone,
            email: requester.email,
          )
        )
      end
    end
  end
end
