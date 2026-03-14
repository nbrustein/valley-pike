require "rails_helper"

RSpec.describe Shared::ContactFieldsComponent, type: :component do
  let(:form) { ActionView::Helpers::FormBuilder.new("ride_request", nil, vc_test_controller.view_context, {}) }

  def render_component(**attrs)
    render_inline(described_class.new(form:, label: "Contact", **attrs))
  end

  context "when editable" do
    before do
      allow(Shared::TextFieldComponent).to receive(:new).and_call_original
    end

    it "renders all three fields" do
      render_component
      aggregate_failures do
        expect(page).to have_css("input[name='ride_request[contact_full_name]']")
        expect(page).to have_css("input[name='ride_request[contact_phone]']")
        expect(page).to have_css("input[name='ride_request[contact_email]']")
      end
    end

    it "passes values to the fields" do
      render_component(full_name: "Jane Doe", phone: "555-1234", email: "jane@example.com")
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

    it "marks name as required when required_name is true" do
      render_component(required_name: true)
      expect(Shared::TextFieldComponent).to have_received(:new).with(
        hash_including(field: :contact_full_name, required: true)
      )
    end
  end

  context "when readonly" do
    it "renders the label" do
      render_component(readonly: true)
      expect(page).to have_css("p.font-semibold", text: "Contact")
    end

    it "does not render form inputs" do
      render_component(readonly: true)
      expect(page).not_to have_css("input")
    end

    it "renders all contact info on separate lines" do
      render_component(readonly: true, full_name: "Jane Doe", phone: "555-1234", email: "jane@example.com")
      expect(page).to have_text("Jane Doe")
      expect(page).to have_text("555-1234")
      expect(page).to have_text("jane@example.com")
    end

    it "handles missing values" do
      render_component(readonly: true, full_name: "Jane Doe", phone: nil, email: "jane@example.com")
      expect(page).to have_text("Jane Doe")
      expect(page).to have_text("jane@example.com")
      expect(page).not_to have_css("br + br")
    end

    it "renders nothing when all values are nil" do
      render_component(readonly: true)
      expect(page).to have_css("p.font-semibold", text: "Contact")
      value_el = page.find_all("p").last
      expect(value_el.text).to be_empty
    end
  end
end
