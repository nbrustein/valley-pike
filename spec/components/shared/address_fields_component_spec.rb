require "rails_helper"

RSpec.describe Shared::AddressFieldsComponent, type: :component do
  let(:form) { ActionView::Helpers::FormBuilder.new("ride_request", nil, vc_test_controller.view_context, {}) }

  def render_component(value: nil)
    render_inline(described_class.new(form:, field: :pick_up_address, label: "Pick Up Address", value:))
  end

  it "renders inputs for all address fields" do
    render_component
    aggregate_failures do
      expect(page).to have_css("input[name='ride_request[pick_up_address][name]']")
      expect(page).to have_css("input[name='ride_request[pick_up_address][street_address]']")
      expect(page).to have_css("input[name='ride_request[pick_up_address][city]']")
      expect(page).to have_css("input[name='ride_request[pick_up_address][state]']")
    end
  end

  it "renders labels for all fields" do
    render_component
    aggregate_failures do
      expect(page).to have_css("legend", text: "Name")
      expect(page).to have_css("legend", text: "Street Address")
      expect(page).to have_css("legend", text: "City")
      expect(page).to have_css("legend", text: "State")
    end
  end

  context "when readonly" do
    def render_readonly(value: nil)
      render_inline(described_class.new(
        form:, field: :pick_up_address, label: "Pick Up Address", value:, readonly: true
      ))
    end

    it "renders the label" do
      render_readonly
      expect(page).to have_css("p.font-semibold", text: "Pick Up Address")
    end

    it "does not render form inputs" do
      render_readonly
      expect(page).not_to have_css("input")
    end

    it "renders each address part on its own line" do
      address = build_stubbed(:address,
        name: "City Hospital", street_address: "100 Main St", city: "Richmond", state: "VA")
      render_readonly(value: address)
      expect(page).to have_text("City Hospital")
      expect(page).to have_text("100 Main St")
      expect(page).to have_text("Richmond, VA")
    end

    it "handles missing name" do
      address = build_stubbed(:address, name: "", street_address: "100 Main St", city: "Richmond", state: "VA")
      render_readonly(value: address)
      expect(page).not_to have_text("City Hospital")
      expect(page).to have_text("100 Main St")
      expect(page).to have_text("Richmond, VA")
    end

    it "handles missing city" do
      address = build_stubbed(:address, name: "Home", street_address: "100 Main St", city: "", state: "VA")
      render_readonly(value: address)
      expect(page).to have_text("Home")
      expect(page).to have_text("100 Main St")
      expect(page).to have_text("VA")
    end

    it "renders nothing when value is nil" do
      render_readonly(value: nil)
      expect(page).to have_css("p.font-semibold", text: "Pick Up Address")
      value_el = page.find_all("p").last
      expect(value_el.text).to be_empty
    end
  end

  context "when an existing address is provided" do
    let(:address) {
      build_stubbed(:address,
        name: "City Hospital",
        street_address: "100 Main St",
        city: "Richmond",
        state: "VA")
    }

    it "pre-fills the field values" do
      render_component(value: address)
      aggregate_failures do
        expect(page).to have_css("input[value='City Hospital']")
        expect(page).to have_css("input[value='100 Main St']")
        expect(page).to have_css("input[value='Richmond']")
        expect(page).to have_css("input[value='VA']")
      end
    end
  end
end
