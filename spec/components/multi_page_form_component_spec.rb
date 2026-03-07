require "rails_helper"

RSpec.describe MultiPageFormComponent, type: :component do
  let(:page_paths) { [ "/step/1", "/step/2", "/step/3" ] }

  def build(current_page:, last_page_label: "Submit", form_method: :post)
    described_class.new(
      form_action: "/ride_requests",
      form_method:,
      page_paths:,
      current_page:,
      last_page_label:
    )
  end

  describe "form" do
    it "renders a form pointing to form_action" do
      render_inline(build(current_page: 1))
      expect(page).to have_css("form[action='/ride_requests']")
    end

    it "yields content inside the form" do
      render_inline(build(current_page: 1)) { "<p>Page content</p>".html_safe }
      expect(page).to have_css("form p", text: "Page content")
    end
  end

  describe "Previous button" do
    context "when on the first page" do
      it "does not render a Previous link" do
        render_inline(build(current_page: 1))
        expect(page).not_to have_link("Previous")
      end

      it "uses justify-end layout" do
        render_inline(build(current_page: 1))
        expect(page).to have_css(".justify-end")
        expect(page).not_to have_css(".justify-between")
      end
    end

    context "when on a middle page" do
      it "renders a Previous link to the preceding page path" do
        render_inline(build(current_page: 2))
        expect(page).to have_link("Previous", href: "/step/1")
      end

      it "uses justify-between layout" do
        render_inline(build(current_page: 2))
        expect(page).to have_css(".justify-between")
        expect(page).not_to have_css(".justify-end")
      end
    end

    context "when on the last page" do
      it "renders a Previous link to the preceding page path" do
        render_inline(build(current_page: 3))
        expect(page).to have_link("Previous", href: "/step/2")
      end
    end
  end

  describe "Next/Submit button" do
    context "when not on the last page" do
      it "renders a submit button labelled 'Save and Continue'" do
        render_inline(build(current_page: 1))
        expect(page).to have_button("Save and Continue")
      end
    end

    context "when on the last page" do
      it "renders a submit button with the last_page_label" do
        render_inline(build(current_page: 3, last_page_label: "Publish"))
        expect(page).to have_button("Publish")
        expect(page).not_to have_button("Save and Continue")
      end

      it "defaults last_page_label to 'Submit'" do
        render_inline(build(current_page: 3))
        expect(page).to have_button("Submit")
      end
    end
  end
end
