require "rails_helper"

RSpec.describe WelcomeComponent, type: :component do
  describe "title" do
    it "renders the welcome heading" do
      render_inline(described_class.new(identity: nil))
      expect(page).to have_css("h1", text: "Welcome")
    end
  end

  describe "signed out state" do
    before { render_inline(described_class.new(identity: nil)) }

    it "shows the sign-in form" do
      expect(page).to have_text("Sign in with a magic link")
      expect(page).to have_text("Sign in with password")
    end
  end

  describe "signed in state" do
    let(:identity) { build_stubbed(:identity, :magic_link, email: "user@example.com") }

    before { render_inline(described_class.new(identity:)) }

    it "shows the signed-in email" do
      expect(page).to have_text("Signed in as user@example.com")
    end

    it "shows the sign-out button" do
      expect(page).to have_button("Sign out")
    end
  end
end
