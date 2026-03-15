require "rails_helper"

RSpec.describe DriverRideRequestPolicy do
  let(:policy) { DriverRideRequestPolicy.new(current_user, RideRequest) }
  let(:scope) { described_class::Scope.new(current_user, RideRequest).resolve }

  describe "#index?" do
    subject { policy.index? }

    context "when the user is nil" do
      let(:current_user) { nil }

      it { is_expected.to be(false) }
    end

    context "when the user is not a driver" do
      let(:current_user) { create(:user, role: UserRole::VANITA_VIEWER) }

      it { is_expected.to be(false) }
    end

    context "when the user is a driver" do
      let(:current_user) { create(:user, role: UserRole::DRIVER) }

      it { is_expected.to be(true) }
    end
  end

  describe "#scope" do
    let(:org_no_quals) { create(:organization, required_qualifications: []) }
    let(:org_with_quals) { create(:organization, required_qualifications: [ DriverQualification::QUALIFICATION_CWS_VETTED ]) }
    let(:current_user) { create(:user, role: UserRole::DRIVER) }

    context "when the user is not a driver" do
      let(:current_user) { create(:user, role: UserRole::VANITA_VIEWER) }

      it "returns an empty result" do
        create(:ride_request, organization: org_no_quals)
        expect(scope).to be_empty
      end
    end

    context "when the driver is assigned to a ride" do
      let!(:past_ride) { create_ride_request_with_past_date(organization: org_no_quals, date: 1.day.ago) }
      let!(:completed_ride) { create(:ride_request, organization: org_no_quals, completed: true) }
      let!(:canceled_ride) { create(:ride_request, organization: org_no_quals, cancelled: true) }

      before do
        create(:driver_assignment, ride_request: past_ride, driver: current_user)
        create(:driver_assignment, ride_request: completed_ride, driver: current_user)
        create(:driver_assignment, ride_request: canceled_ride, driver: current_user)
      end

      it "includes assigned past rides" do
        expect(scope).to include(past_ride)
      end

      it "includes assigned completed rides" do
        expect(scope).to include(completed_ride)
      end

      it "includes assigned canceled rides" do
        expect(scope).to include(canceled_ride)
      end
    end

    context "when the driver is not assigned" do
      let!(:future_ride) { create(:ride_request, organization: org_no_quals, date: 1.day.from_now) }
      let!(:today_ride) { create(:ride_request, organization: org_no_quals, date: Date.current) }
      let!(:past_ride) { create_ride_request_with_past_date(organization: org_no_quals, date: 1.day.ago) }
      let!(:completed_ride) { create(:ride_request, organization: org_no_quals, completed: true) }
      let!(:canceled_ride) { create(:ride_request, organization: org_no_quals, cancelled: true) }

      it "includes future rides the driver qualifies for" do
        expect(scope).to include(future_ride)
      end

      it "includes today's rides" do
        expect(scope).to include(today_ride)
      end

      it "excludes past rides" do
        expect(scope).not_to include(past_ride)
      end

      it "excludes completed rides" do
        expect(scope).not_to include(completed_ride)
      end

      it "excludes canceled rides" do
        expect(scope).not_to include(canceled_ride)
      end
    end

    context "with qualification requirements" do
      let!(:vetted_ride) { create(:ride_request, organization: org_with_quals, date: 1.day.from_now) }
      let!(:unvetted_ride) { create(:ride_request, organization: org_no_quals, date: 1.day.from_now) }

      context "when the driver lacks required qualifications" do
        it "excludes rides from organizations requiring those qualifications" do
          expect(scope).not_to include(vetted_ride)
        end

        it "includes rides from organizations with no requirements" do
          expect(scope).to include(unvetted_ride)
        end
      end

      context "when the driver has all required qualifications" do
        before do
          create(:driver_qualification, user: current_user, qualification: DriverQualification::QUALIFICATION_CWS_VETTED)
        end

        it "includes rides from organizations requiring those qualifications" do
          expect(scope).to include(vetted_ride)
        end
      end
    end
  end

  private

  def create_ride_request_with_past_date(organization:, date:)
    ride_request = create(:ride_request, organization:)
    ride_request.update_column(:date, date)
    ride_request
  end
end
