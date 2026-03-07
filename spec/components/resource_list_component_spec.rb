require "rails_helper"

RSpec.describe ResourceListComponent, type: :component do
  describe "column headers" do
    it "renders each column as a th" do
      render_inline(described_class.new(columns: [ "Name", "Role" ]))
      expect(page).to have_css("th", text: "Name")
      expect(page).to have_css("th", text: "Role")
    end

    it "renders an empty th after the columns for the action icon" do
      render_inline(described_class.new(columns: [ "Name" ]))
      ths = page.all("thead th")
      expect(ths.count).to eq(2)
      expect(ths.last.text).to eq("")
    end
  end

  describe "content" do
    it "yields into tbody" do
      render_inline(described_class.new(columns: [ "Name" ])) { "<tr><td>Row</td></tr>".html_safe }
      expect(page).to have_css("tbody tr td", text: "Row")
    end
  end
end
