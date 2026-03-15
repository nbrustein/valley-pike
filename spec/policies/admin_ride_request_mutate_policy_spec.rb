require "rails_helper"

RSpec.describe AdminRideRequestMutatePolicy do
  let(:policy) { described_class.new(current_user, nil) }

  describe "#new?" do
    subject { policy.new? }

    context "when the user is nil" do
      let(:current_user) { nil }

      it { is_expected.to be(false) }
    end

    context "when the user has no relevant role" do
      let(:current_user) { create(:user, role: UserRole::VANITA_VIEWER) }

      it { is_expected.to be(false) }
    end

    context "when the user does not have a relevant role" do
      let(:current_user) { create(:user, role: UserRole::DRIVER) }

      it { is_expected.to be(false) }
    end

    context "when the user has a relevant role" do
      let(:org) { create(:organization) }
      let(:current_user) { create(:user, role: UserRole::ORG_ADMIN, role_organization: org) }

      it { is_expected.to be(true) }
    end
  end

  describe "#create?" do
    let(:org) { create(:organization) }
    let(:other_org) { create(:organization) }
    let(:uow) { UnitsOfWork::CreateRideRequest.new(executor_id: current_user&.id, params: {organization_id: org.id}) }
    let(:policy) { described_class.new(current_user, uow) }

    subject { policy.create? }

    context "when the user is nil" do
      let(:current_user) { nil }
      let(:uow) { nil }
      let(:policy) { described_class.new(nil, nil) }

      it { is_expected.to be(false) }
    end

    context "when the record is not a UoW" do
      let(:current_user) { create(:user, role: UserRole::VANITA_ADMIN) }
      let(:policy) { described_class.new(current_user, nil) }

      it { is_expected.to be(false) }
    end

    context "when the user has no relevant role" do
      let(:current_user) { create(:user, role: UserRole::VANITA_VIEWER) }

      it { is_expected.to be(false) }
    end

    context "when the user has a relevant role" do
      let(:current_user) { create(:user, role: UserRole::VANITA_ADMIN) }

      it { is_expected.to be(true) }
    end

    context "when the user has an org-specific role for a different org" do
      let(:current_user) { create(:user, role: UserRole::RIDE_REQUESTER, role_organization: other_org) }

      it { is_expected.to be(false) }
    end

    context "when the user has an org-specific role for the same org" do
      let(:current_user) { create(:user, role: UserRole::RIDE_REQUESTER, role_organization: org) }

      it { is_expected.to be(true) }
    end

    context "when the user has a relevant global role" do
      let(:current_user) { create(:user, role: UserRole::VANITA_ADMIN) }

      it { is_expected.to be(true) }
    end
  end
end
