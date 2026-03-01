require "rails_helper"

RSpec.describe UsersHelper do
  let(:current_user) { build(:user) }
  let(:scope_instance) { instance_double(UserViewPolicy::Scope) }

  before do
    allow(UserViewPolicy::Scope).to receive(:new).with(current_user, nil).and_return(scope_instance)
    user = current_user
    helper.define_singleton_method(:current_user) { user }
    helper.clear_memery_cache!
  end

  describe "#show_users_index_link?" do
    context "when the policy scope has results" do
      before do
        allow(scope_instance).to receive(:resolve)
          .and_return(instance_double("Relation", exists?: true))
      end

      it "returns true" do
        expect(helper.show_users_index_link?).to be(true)
      end
    end

    context "when the policy scope has no results" do
      before do
        allow(scope_instance).to receive(:resolve)
          .and_return(instance_double("Relation", exists?: false))
      end

      it "returns false" do
        expect(helper.show_users_index_link?).to be(false)
      end
    end
  end
end
