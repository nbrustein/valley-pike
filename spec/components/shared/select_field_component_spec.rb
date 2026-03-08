require "rails_helper"

RSpec.describe Shared::SelectFieldComponent, type: :component do
  let(:form) { ActionView::Helpers::FormBuilder.new("ride_request", nil, vc_test_controller.view_context, {}) }
  let(:options) { [ [ "Org A", 1 ], [ "Org B", 2 ] ] }

  def render_component(**attrs)
    render_inline(described_class.new(form:, field: :organization_id, label: "Organization", options:, **attrs))
  end

  context "when there is only one option" do
    let(:options) { [ [ "Org A", 1 ] ] }

    it "renders a hidden input" do
      render_component
      expect(page).to have_css(
        "input[type='hidden'][name='ride_request[organization_id]']",
        visible: :hidden
      )
    end

    it "does not render a select" do
      render_component
      expect(page).not_to have_css("select")
    end
  end

  context "when there are multiple options" do
    it "renders a select" do
      render_component
      expect(page).to have_css("select[name='ride_request[organization_id]']")
    end

    it "renders each option" do
      render_component
      aggregate_failures do
        expect(page).to have_css("option", text: "Org A")
        expect(page).to have_css("option", text: "Org B")
      end
    end

    it "marks the matching option as selected" do
      render_component(selected: 2)
      expect(page).to have_css("option[selected]", text: "Org B")
    end
  end

  context "when readonly" do
    it "renders the label and selected value as text" do
      render_component(selected: 1, readonly: true)
      aggregate_failures do
        expect(page).to have_css("p", text: "Organization")
        expect(page).to have_css("p", text: "Org A")
      end
    end

    it "does not render a select or input" do
      render_component(selected: 1, readonly: true)
      aggregate_failures do
        expect(page).not_to have_css("select")
        expect(page).not_to have_css("input")
      end
    end

    context "when there is only one option" do
      let(:options) { [ [ "Org A", 1 ] ] }

      it "renders the option label as text rather than a hidden input" do
        render_component(readonly: true)
        expect(page).to have_css("p", text: "Org A")
        expect(page).not_to have_css("input")
      end
    end
  end
end
