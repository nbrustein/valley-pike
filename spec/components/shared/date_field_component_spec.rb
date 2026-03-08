require "rails_helper"

RSpec.describe Shared::DateFieldComponent, type: :component do
  let(:form) { ActionView::Helpers::FormBuilder.new("model", nil, vc_test_controller.view_context, {}) }

  def render_component(**attrs)
    render_inline(described_class.new(form:, field: :date, label: "Ride Date", value: "2026-06-15", **attrs))
  end

  context "when not readonly" do
    it "renders a label and date input" do
      render_component
      aggregate_failures do
        expect(page).to have_css("label", text: "Ride Date")
        expect(page).to have_css("input[type='date']")
      end
    end

    it "populates the value" do
      render_component
      expect(page).to have_css("input[value='2026-06-15']")
    end

    it "marks the input as required" do
      render_component(required: true)
      expect(page).to have_css("input[required]")
    end

    it "does not mark the input as required by default" do
      render_component
      expect(page).not_to have_css("input[required]")
    end
  end

  context "when readonly" do
    it "renders the label and value as text" do
      render_component(readonly: true)
      aggregate_failures do
        expect(page).to have_css("p", text: "Ride Date")
        expect(page).to have_css("p", text: "2026-06-15")
      end
    end

    it "does not render an input" do
      render_component(readonly: true)
      expect(page).not_to have_css("input")
    end
  end
end
