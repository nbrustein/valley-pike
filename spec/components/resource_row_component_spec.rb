require "rails_helper"

RSpec.describe ResourceRowComponent, type: :component do
  context "when edit_path is provided" do
    it "renders an edit icon, link, and clickable row" do
      render_inline(described_class.new(edit_path: "/users/1/edit"))

      aggregate_failures do
        expect(page).to have_link(href: "/users/1/edit")
        expect(page).to have_css("i.fa-pen-to-square")
        expect(page).not_to have_css("i.fa-eye")
        expect(page).not_to have_css("i.fa-lock")
        expect(page).to have_css("tr.cursor-pointer")
      end
    end
  end

  context "when only show_path is provided" do
    it "renders an eye icon, link, and clickable row" do
      render_inline(described_class.new(show_path: "/users/1"))

      aggregate_failures do
        expect(page).to have_link(href: "/users/1")
        expect(page).to have_css("i.fa-eye")
        expect(page).not_to have_css("i.fa-pen-to-square")
        expect(page).not_to have_css("i.fa-lock")
        expect(page).to have_css("tr.cursor-pointer")
      end
    end
  end

  context "when neither edit_path nor show_path is provided" do
    it "renders a lock icon with no link and no cursor-pointer" do
      render_inline(described_class.new)

      aggregate_failures do
        expect(page).to have_css("i.fa-lock")
        expect(page).not_to have_css("a")
        expect(page).not_to have_css("i.fa-pen-to-square")
        expect(page).not_to have_css("i.fa-eye")
        expect(page).not_to have_css("tr.cursor-pointer")
      end
    end
  end

  context "when both edit_path and show_path are provided" do
    it "uses edit_path (edit takes priority)" do
      render_inline(described_class.new(edit_path: "/users/1/edit", show_path: "/users/1"))
      aggregate_failures do
        expect(page).to have_css("i.fa-pen-to-square")
        expect(page).not_to have_css("i.fa-eye")
      end
    end
  end

  describe "data attributes" do
    it "applies data attributes to the tr" do
      render_inline(described_class.new(data: {user_id: "abc123"}))
      expect(page).to have_css("tr[data-user-id='abc123']")
    end
  end

  describe "content" do
    it "yields cell content into the tr" do
      render_inline(described_class.new) { "<td>Cell content</td>".html_safe }
      expect(page).to have_css("td", text: "Cell content")
    end
  end
end
