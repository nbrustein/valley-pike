require "rails_helper"

RSpec.describe RideRequestMutate::FormStep4Component, type: :component do
  def build_form(ride_request=nil)
    ActionView::Helpers::FormBuilder.new("ride_request", ride_request, vc_test_controller.view_context, {})
  end

  def render_component(ride_request: nil, requester: nil)
    render_inline(described_class.new(form: build_form(ride_request), ride_request:, requester:))
  end

  before do
    allow(Shared::TextFieldComponent).to receive(:new).and_call_original
  end

  describe "contact_full_name_field" do
    it "passes the correct arguments to TextFieldComponent" do
      render_component
      expect(Shared::TextFieldComponent).to have_received(:new).with(
        form: anything,
        field: :contact_full_name,
        label: "Contact Name",
        value: nil,
        required: true,
      )
    end

    context "when a ride request with contact_full_name is provided" do
      it "passes contact_full_name as value" do
        rr = build_stubbed(:draft_ride_request, contact_full_name: "Alice Smith")
        render_component(ride_request: rr)
        expect(Shared::TextFieldComponent).to have_received(:new).with(
          hash_including(field: :contact_full_name, value: "Alice Smith")
        )
      end
    end

    context "when no ride request value but requester is provided" do
      it "defaults to requester's full name" do
        requester = build(:user)
        render_component(requester:)
        expect(Shared::TextFieldComponent).to have_received(:new).with(
          hash_including(field: :contact_full_name, value: requester.human.full_name)
        )
      end
    end
  end

  describe "contact_phone_field" do
    it "passes the correct arguments to TextFieldComponent" do
      render_component
      expect(Shared::TextFieldComponent).to have_received(:new).with(
        form: anything,
        field: :contact_phone,
        label: "Contact Phone",
        value: nil,
        type: :phone,
      )
    end

    context "when a ride request with contact_phone is provided" do
      it "passes contact_phone as value" do
        rr = build_stubbed(:draft_ride_request, contact_phone: "555-1234")
        render_component(ride_request: rr)
        expect(Shared::TextFieldComponent).to have_received(:new).with(
          hash_including(field: :contact_phone, value: "555-1234")
        )
      end
    end

    context "when no ride request value but requester is provided" do
      it "defaults to requester's phone" do
        requester = build(:user)
        render_component(requester:)
        expect(Shared::TextFieldComponent).to have_received(:new).with(
          hash_including(field: :contact_phone, value: requester.human.phone)
        )
      end
    end
  end

  describe "contact_email_field" do
    it "passes the correct arguments to TextFieldComponent" do
      render_component
      expect(Shared::TextFieldComponent).to have_received(:new).with(
        form: anything,
        field: :contact_email,
        label: "Contact Email",
        value: nil,
        type: :email,
      )
    end

    context "when a ride request with contact_email is provided" do
      it "passes contact_email as value" do
        rr = build_stubbed(:draft_ride_request, contact_email: "alice@example.com")
        render_component(ride_request: rr)
        expect(Shared::TextFieldComponent).to have_received(:new).with(
          hash_including(field: :contact_email, value: "alice@example.com")
        )
      end
    end

    context "when no ride request value but requester is provided" do
      it "defaults to requester's email" do
        requester = build(:user)
        render_component(requester:)
        expect(Shared::TextFieldComponent).to have_received(:new).with(
          hash_including(field: :contact_email, value: requester.email)
        )
      end
    end
  end
end
