require "rails_helper"

RSpec.describe AdminRideRequestViewPolicy do
  let(:policy) { AdminRideRequestViewPolicy.new(current_user, RideRequest) }
  let(:scope) { described_class::Scope.new(current_user, RideRequest).resolve }

  describe "#index?" do
    subject { policy.index? }

    context "when the user is nil" do
      let(:current_user) { nil }

      it { is_expected.to be(false) }
    end

    context "when the user has no relevant role" do
      let(:current_user) { create(:user, role: UserRole::DRIVER) }

      it { is_expected.to be(false) }
    end

    context "when the user has a relevant global role" do
      let(:current_user) { create(:user, role: UserRole::VANITA_VIEWER) }

      it { is_expected.to be(true) }
    end

    context "when the user has a relevant org role" do
      let(:org) { create(:organization) }
      let(:current_user) { create(:user, role: UserRole::RIDE_REQUESTER, role_organization: org) }

      it { is_expected.to be(true) }
    end
  end

  describe "#scope" do
    let(:org1) { create(:organization) }
    let(:org2) { create(:organization) }
    let!(:published_org1) { create(:ride_request, organization: org1) }
    let!(:published_org2) { create(:ride_request, organization: org2) }

    context "when the user is a VANITA_VIEWER" do
      let(:current_user) { create(:user, role: UserRole::VANITA_VIEWER) }
      let!(:someone_elses_draft) { create(:draft_ride_request, organization: org1) }

      it "returns all published ride requests" do
        expect(scope).to include(published_org1, published_org2)
      end

      it "does not return drafts belonging to others" do
        expect(scope).not_to include(someone_elses_draft)
      end

      it "returns own drafts" do
        own_draft = create(:draft_ride_request, organization: org1, requester: current_user)
        expect(scope).to include(own_draft)
      end
    end

    context "when the user is a RIDE_REQUESTER for org1" do
      let(:current_user) { create(:user, role: UserRole::RIDE_REQUESTER, role_organization: org1) }
      let!(:org1_draft) { create(:draft_ride_request, organization: org1, requester: current_user) }
      let!(:other_draft) { create(:draft_ride_request, organization: org1) }

      it "returns published ride requests for their org" do
        expect(scope).to include(published_org1)
      end

      it "does not return published ride requests for other orgs" do
        expect(scope).not_to include(published_org2)
      end

      it "returns their own drafts" do
        expect(scope).to include(org1_draft)
      end

      it "does not return drafts belonging to others" do
        expect(scope).not_to include(other_draft)
      end
    end

    context "when the user is a DEVELOPER" do
      let(:current_user) { create(:user, role: UserRole::DEVELOPER) }
      let!(:draft_org1) { create(:draft_ride_request, organization: org1) }
      let!(:draft_org2) { create(:draft_ride_request, organization: org2) }

      it "returns all published ride requests" do
        expect(scope).to include(published_org1, published_org2)
      end

      it "returns all drafts" do
        expect(scope).to include(draft_org1, draft_org2)
      end
    end

    context "when the user has no index permission" do
      let(:current_user) { create(:user, role: UserRole::DRIVER) }

      it "returns an empty result" do
        expect(scope).to be_empty
      end
    end
  end
end
