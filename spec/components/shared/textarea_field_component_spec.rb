require "rails_helper"

RSpec.describe Shared::TextareaFieldComponent, type: :component do
  let(:form) { ActionView::Helpers::FormBuilder.new("model", nil, vc_test_controller.view_context, {}) }

  def render_component(**attrs)
    render_inline(described_class.new(form:, field: :description, label: "Description", value: "test value", **attrs))
  end

  context "when not readonly" do
    it "renders a label and textarea" do
      render_component
      aggregate_failures do
        expect(page).to have_css("label", text: "Description")
        expect(page).to have_css("textarea[name='model[description]']")
      end
    end

    it "populates the value" do
      render_component
      expect(page).to have_css("textarea", text: "test value")
    end

    it "renders description between label and textarea" do
      render_component(description: "Help text here")
      expect(page).to have_css("p", text: "Help text here")
    end

    it "does not render a description element when none provided" do
      render_component
      expect(page).not_to have_css("p.text-xs")
    end

    it "marks the textarea as required" do
      render_component(required: true)
      expect(page).to have_css("textarea[required]")
    end

    it "does not mark the textarea as required by default" do
      render_component
      expect(page).not_to have_css("textarea[required]")
    end

    it "sets the placeholder on the textarea" do
      render_component(placeholder: "Enter a description")
      expect(page).to have_css("textarea[placeholder='Enter a description']")
    end

    it "does not set a placeholder attribute when none provided" do
      render_component
      expect(page).not_to have_css("textarea[placeholder]")
    end

    it "sets the rows attribute on the textarea" do
      render_component(rows: 6)
      expect(page).to have_css("textarea[rows='6']")
    end

    it "does not render a label element when label is nil" do
      render_inline(described_class.new(form:, field: :description, value: "test"))
      expect(page).not_to have_css("label")
    end
  end

  context "when readonly" do
    it "renders the label and value as text" do
      render_component(readonly: true)
      aggregate_failures do
        expect(page).to have_css("p", text: "Description")
        expect(page).to have_css("p", text: "test value")
      end
    end

    it "does not render a textarea" do
      render_component(readonly: true)
      expect(page).not_to have_css("textarea")
    end

    it "does not render the description" do
      render_component(readonly: true, description: "Help text here")
      expect(page).not_to have_css("p", text: "Help text here")
    end
  end
end
