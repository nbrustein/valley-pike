require "rails_helper"

RSpec.describe Shared::TextFieldComponent, type: :component do
  let(:form) { ActionView::Helpers::FormBuilder.new("model", nil, vc_test_controller.view_context, {}) }

  def render_component(**attrs)
    render_inline(described_class.new(form:, field: :name, label: "Name", value: "test value", **attrs))
  end

  context "when not readonly" do
    it "renders a label and text input" do
      render_component
      aggregate_failures do
        expect(page).to have_css("legend", text: "Name")
        expect(page).to have_field("Name", type: "text", with: "test value")
      end
    end

    it "renders an email input for type: :email" do
      render_component(type: :email)
      expect(page).to have_css("input[type='email']")
    end

    it "renders a phone input for type: :phone" do
      render_component(type: :phone)
      expect(page).to have_css("input[type='tel']")
    end

    it "raises for an unknown type" do
      expect { render_component(type: :fax) }.to raise_error(ArgumentError)
    end

    it "renders description between label and input" do
      render_component(description: "Help text here")
      expect(page).to have_css("p", text: "Help text here")
    end

    it "does not render a description element when none provided" do
      render_component
      expect(page).not_to have_css("p.text-xs")
    end

    it "marks the input as required" do
      render_component(required: true)
      expect(page).to have_css("input[required]")
    end

    it "applies data attributes to the input" do
      render_component(data: {my_target: true})
      expect(page).to have_css("input[data-my-target]")
    end

    it "sets the placeholder on the input" do
      render_component(placeholder: "Enter a name")
      expect(page).to have_css("input[placeholder='Enter a name']")
    end

    it "does not set a placeholder attribute when none provided" do
      render_component
      expect(page).not_to have_css("input[placeholder]")
    end
  end

  context "when readonly" do
    it "renders the label and value as text" do
      render_component(readonly: true)
      aggregate_failures do
        expect(page).to have_css("p", text: "Name")
        expect(page).to have_css("p", text: "test value")
      end
    end

    it "does not render an input" do
      render_component(readonly: true)
      expect(page).not_to have_css("input")
    end

    it "does not render the description" do
      render_component(readonly: true, description: "Help text here")
      expect(page).not_to have_css("p", text: "Help text here")
    end
  end
end
