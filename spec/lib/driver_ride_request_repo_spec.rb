require "rails_helper"

RSpec.describe DriverRideRequestRepo do
  let(:organization) { create(:organization, required_qualifications: []) }
  let(:driver) { create(:user, role: UserRole::DRIVER) }
  let(:repo) { described_class.new(current_user: driver) }

  describe "#list" do
    def list_ids
      repo.list.map(&:id)
    end

    describe "scoping" do
      it "only returns ride requests the driver is allowed to see" do
        visible = create(:ride_request, organization:, date: 1.day.from_now)
        draft = create(:draft_ride_request, organization:)

        expect(list_ids).to include(visible.id)
        expect(list_ids).not_to include(draft.id)
      end
    end

    describe "sort order" do
      describe "future before past" do
        let!(:future_ride) { create(:ride_request, organization:, date: 1.day.from_now) }
        let!(:past_ride) { create_past_ride(date: 1.day.ago) }

        before { create(:driver_assignment, ride_request: past_ride, driver:) }

        it "sorts future rides before past rides" do
          expect(list_ids).to eq([ future_ride.id, past_ride.id ])
        end
      end

      describe "assigned before unassigned" do
        let!(:unassigned) { create(:ride_request, organization:, date: 2.days.from_now) }
        let!(:assigned) { create(:ride_request, organization:, date: 3.days.from_now) }

        before { create(:driver_assignment, ride_request: assigned, driver:) }

        it "sorts assigned rides before unassigned rides within the same time bucket" do
          expect(list_ids).to eq([ assigned.id, unassigned.id ])
        end
      end

      describe "needs drivers before fully staffed" do
        let!(:needs_drivers) { create(:ride_request, organization:, date: 2.days.from_now, has_enough_drivers: false) }
        let!(:fully_staffed) { create(:ride_request, organization:, date: 3.days.from_now, has_enough_drivers: true) }

        it "sorts rides needing drivers before fully staffed rides" do
          expect(list_ids).to eq([ needs_drivers.id, fully_staffed.id ])
        end
      end

      describe "date ascending for future, descending for past" do
        let!(:future_soon) { create(:ride_request, organization:, date: 1.day.from_now) }
        let!(:future_later) { create(:ride_request, organization:, date: 5.days.from_now) }
        let!(:past_recent) { create_past_ride(date: 1.day.ago) }
        let!(:past_older) { create_past_ride(date: 5.days.ago) }

        before do
          create(:driver_assignment, ride_request: past_recent, driver:)
          create(:driver_assignment, ride_request: past_older, driver:)
        end

        it "sorts future rides by date ascending and past rides by date descending" do
          expect(list_ids).to eq([
            future_soon.id, future_later.id,
            past_recent.id, past_older.id
          ])
        end
      end

      describe "full sort priority" do
        let!(:future_assigned) { create(:ride_request, organization:, date: 2.days.from_now) }
        let!(:future_unassigned_needs) do
          create(:ride_request, organization:, date: 1.day.from_now, has_enough_drivers: false)
        end
        let!(:future_unassigned_full) do
          create(:ride_request, organization:, date: 1.day.from_now, has_enough_drivers: true)
        end
        let!(:past_assigned) { create_past_ride(date: 1.day.ago) }

        before do
          create(:driver_assignment, ride_request: future_assigned, driver:)
          create(:driver_assignment, ride_request: past_assigned, driver:)
        end

        it "applies all sort criteria in priority order", :aggregate_failures do
          ids = list_ids
          future_ids = [ future_assigned.id, future_unassigned_needs.id, future_unassigned_full.id ]
          past_ids = [ past_assigned.id ]

          expect(ids).to eq(future_ids + past_ids)
        end
      end
    end

    describe "eager loading" do
      let!(:ride_request) do
        create(:ride_request, organization:, date: 1.day.from_now,
          destination_address: create(:address))
      end

      it "eager loads organization, destination_address, and driver_assignments" do
        results = repo.list
        result = results.first

        expect(result.association(:organization)).to be_loaded
        expect(result.association(:destination_address)).to be_loaded
        expect(result.association(:driver_assignments)).to be_loaded
      end
    end
  end

  private

  def create_past_ride(date:)
    ride_request = create(:ride_request, organization:)
    ride_request.update_column(:date, date)
    ride_request
  end
end
