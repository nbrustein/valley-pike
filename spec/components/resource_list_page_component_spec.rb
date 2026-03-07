require "rails_helper"

RSpec.describe ResourceListPageComponent, type: :component do
  describe "title" do
    it "renders the title" do
      render_inline(described_class.new(title: "Users"))
      expect(page).to have_css("h1", text: "Users")
    end
  end

  describe "create button" do
    context "when create_path is provided" do
      it "renders a create button linking to the path" do
        render_inline(described_class.new(title: "Users", create_path: "/users/new"))
        expect(page).to have_link("Create", href: "/users/new")
      end
    end

    context "when create_path is not provided" do
      it "does not render a create button" do
        render_inline(described_class.new(title: "Users"))
        expect(page).not_to have_css("a")
      end
    end
  end

  describe "content" do
    it "yields inner content" do
      render_inline(described_class.new(title: "Users")) { "inner content" }
      expect(page).to have_text("inner content")
    end
  end
end
