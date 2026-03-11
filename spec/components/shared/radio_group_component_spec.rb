require "rails_helper"

RSpec.describe Shared::RadioGroupComponent, type: :component do
  let(:options) { [ [ "red", "Red" ], [ "blue", "Blue" ] ] }

  def render_component(**attrs)
    render_inline(described_class.new(name: "item[color]", label: "Color", options:, selected: "red", **attrs))
  end

  it "renders the label" do
    render_component
    expect(page).to have_css("legend", text: "Color")
  end

  it "renders each option" do
    render_component
    aggregate_failures do
      expect(page).to have_field("Red", type: "radio")
      expect(page).to have_field("Blue", type: "radio")
    end
  end

  it "checks the selected option" do
    render_component
    aggregate_failures do
      expect(page).to have_checked_field("Red")
      expect(page).to have_unchecked_field("Blue")
    end
  end

  describe "include_none_option" do
    context "when true (default)" do
      it "renders a None option" do
        render_component(include_none_option: true)
        expect(page).to have_field("None", type: "radio")
      end
    end

    context "when false" do
      it "does not render a None option" do
        render_component(include_none_option: false)
        expect(page).not_to have_field("None")
      end
    end
  end

  context "when readonly" do
    it "renders the selected value as humanized text" do
      render_component(readonly: true)
      expect(page).to have_css("p", text: "Red")
    end

    it "does not render radio inputs" do
      render_component(readonly: true)
      expect(page).not_to have_css("input[type='radio']")
    end
  end

  context "with input_data_attr" do
    it "applies the attribute to all radio inputs" do
      render_component(input_data_attr: "data-color-input", include_none_option: true)
      expect(page).to have_css("input[type='radio'][data-color-input]", minimum: 3)
    end
  end
end
