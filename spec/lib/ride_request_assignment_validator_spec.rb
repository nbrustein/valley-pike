require "rails_helper"

RSpec.describe RideRequestAssignmentValidator do
  describe "#validate" do
    describe "draft ride requests with assignments" do
      it "adds an error when a ride request is changed to draft with assignments" do
        ride_request = create(:ride_request)
        create(:driver_assignment, ride_request:)
        ride_request.draft = true

        validator = described_class.new(ride_requests: [ ride_request ])

        expect(validator.validate).to be(false)
        expect(validator.errors.full_messages)
          .to include("Cannot change ride request to draft when drivers are assigned")
      end

      it "passes when a ride request is changed to draft with no assignments" do
        ride_request = create(:ride_request)
        ride_request.draft = true

        validator = described_class.new(ride_requests: [ ride_request ])

        expect(validator.validate).to be(true)
      end
    end

    describe "assignments to drafts" do
      it "adds an error when assigning a driver to a draft ride request" do
        ride_request = create(:draft_ride_request)
        assignment = DriverAssignment.new(ride_request:, driver: create(:user))

        validator = described_class.new(driver_assignments: [ assignment ])

        expect(validator.validate).to be(false)
        expect(validator.errors.full_messages).to include("Cannot assign a driver to a draft ride request")
      end

      it "passes when assigning a driver to a published ride request" do
        ride_request = create(:ride_request)
        assignment = DriverAssignment.new(ride_request:, driver: create(:user))

        validator = described_class.new(driver_assignments: [ assignment ])

        expect(validator.validate).to be(true)
      end
    end

    describe "org change preserves driver qualifications" do
      it "adds an error when org change causes driver to lack required qualifications" do
        org = create(:organization, required_qualifications: [])
        new_org = create(:organization, required_qualifications: [ DriverQualification::QUALIFICATION_CWS_VETTED ])
        driver = create(:user)
        ride_request = create(:ride_request, organization: org)
        create(:driver_assignment, ride_request:, driver:)

        ride_request.organization = new_org

        validator = described_class.new(ride_requests: [ ride_request ])

        expect(validator.validate).to be(false)
        expect(validator.errors.full_messages.first).to include("missing required qualifications")
      end

      it "passes when driver has all required qualifications for the new org" do
        org = create(:organization, required_qualifications: [])
        new_org = create(:organization, required_qualifications: [ DriverQualification::QUALIFICATION_CWS_VETTED ])
        driver = create(:user)
        DriverQualification.create!(user: driver, qualification: DriverQualification::QUALIFICATION_CWS_VETTED)
        ride_request = create(:ride_request, organization: org)
        create(:driver_assignment, ride_request:, driver:)

        ride_request.organization = new_org

        validator = described_class.new(ride_requests: [ ride_request ])

        expect(validator.validate).to be(true)
      end

      it "skips completed ride requests" do
        org = create(:organization, required_qualifications: [])
        new_org = create(:organization, required_qualifications: [ DriverQualification::QUALIFICATION_CWS_VETTED ])
        driver = create(:user)
        ride_request = create(:ride_request, organization: org, completed: true)
        create(:driver_assignment, ride_request:, driver:)

        ride_request.organization = new_org

        validator = described_class.new(ride_requests: [ ride_request ])

        expect(validator.validate).to be(true)
      end

      it "skips canceled ride requests" do
        org = create(:organization, required_qualifications: [])
        new_org = create(:organization, required_qualifications: [ DriverQualification::QUALIFICATION_CWS_VETTED ])
        driver = create(:user)
        ride_request = create(:ride_request, organization: org, cancelled: true)
        create(:driver_assignment, ride_request:, driver:)

        ride_request.organization = new_org

        validator = described_class.new(ride_requests: [ ride_request ])

        expect(validator.validate).to be(true)
      end
    end

    describe "org required qualifications change" do
      it "adds an error when adding a qualification that an assigned driver lacks" do
        org = create(:organization, required_qualifications: [])
        driver = create(:user)
        ride_request = create(:ride_request, organization: org)
        create(:driver_assignment, ride_request:, driver:)

        org.required_qualifications = [ DriverQualification::QUALIFICATION_CWS_VETTED ]

        validator = described_class.new(organizations: [ org ])

        expect(validator.validate).to be(false)
        expect(validator.errors.full_messages.first).to include("missing required qualifications")
      end

      it "passes when all assigned drivers have the new required qualifications" do
        org = create(:organization, required_qualifications: [])
        driver = create(:user)
        DriverQualification.create!(user: driver, qualification: DriverQualification::QUALIFICATION_CWS_VETTED)
        ride_request = create(:ride_request, organization: org)
        create(:driver_assignment, ride_request:, driver:)

        org.required_qualifications = [ DriverQualification::QUALIFICATION_CWS_VETTED ]

        validator = described_class.new(organizations: [ org ])

        expect(validator.validate).to be(true)
      end

      it "skips completed ride requests" do
        org = create(:organization, required_qualifications: [])
        driver = create(:user)
        ride_request = create(:ride_request, organization: org, completed: true)
        create(:driver_assignment, ride_request:, driver:)

        org.required_qualifications = [ DriverQualification::QUALIFICATION_CWS_VETTED ]

        validator = described_class.new(organizations: [ org ])

        expect(validator.validate).to be(true)
      end

      it "skips when required_qualifications has not changed" do
        org = create(:organization, required_qualifications: [])
        driver = create(:user)
        ride_request = create(:ride_request, organization: org)
        create(:driver_assignment, ride_request:, driver:)

        validator = described_class.new(organizations: [ org ])

        expect(validator.validate).to be(true)
      end
    end

    describe "removing driver role" do
      it "adds an error when removing driver role with active assignments" do
        user = create(:user, role: UserRole::DRIVER)
        driver_role = user.user_roles.find_by(role: UserRole::DRIVER)
        ride_request = create(:ride_request)
        create(:driver_assignment, ride_request:, driver: user)

        validator = described_class.new(removed_user_roles: [ driver_role ])

        expect(validator.validate).to be(false)
        expect(validator.errors.full_messages)
          .to include("Cannot remove driver role while user has active ride assignments")
      end

      it "passes when removing driver role with no active assignments" do
        user = create(:user, role: UserRole::DRIVER)
        driver_role = user.user_roles.find_by(role: UserRole::DRIVER)

        validator = described_class.new(removed_user_roles: [ driver_role ])

        expect(validator.validate).to be(true)
      end

      it "passes when removing a non-driver role" do
        user = create(:user, role: UserRole::VANITA_ADMIN)
        admin_role = user.user_roles.find_by(role: UserRole::VANITA_ADMIN)
        ride_request = create(:ride_request)
        create(:driver_assignment, ride_request:, driver: user)

        validator = described_class.new(removed_user_roles: [ admin_role ])

        expect(validator.validate).to be(true)
      end

      it "ignores completed ride assignments" do
        user = create(:user, role: UserRole::DRIVER)
        driver_role = user.user_roles.find_by(role: UserRole::DRIVER)
        ride_request = create(:ride_request, completed: true)
        create(:driver_assignment, ride_request:, driver: user)

        validator = described_class.new(removed_user_roles: [ driver_role ])

        expect(validator.validate).to be(true)
      end

      it "ignores canceled ride assignments" do
        user = create(:user, role: UserRole::DRIVER)
        driver_role = user.user_roles.find_by(role: UserRole::DRIVER)
        ride_request = create(:ride_request, cancelled: true)
        create(:driver_assignment, ride_request:, driver: user)

        validator = described_class.new(removed_user_roles: [ driver_role ])

        expect(validator.validate).to be(true)
      end
    end

    describe "removing driver qualifications" do
      it "adds an error when removing a qualification required by an assigned ride's org" do
        org = create(:organization, required_qualifications: [ DriverQualification::QUALIFICATION_CWS_VETTED ])
        user = create(:user, role: UserRole::DRIVER)
        dq = DriverQualification.create!(user:, qualification: DriverQualification::QUALIFICATION_CWS_VETTED)
        ride_request = create(:ride_request, organization: org)
        create(:driver_assignment, ride_request:, driver: user)

        validator = described_class.new(removed_driver_qualifications: [ dq ])

        expect(validator.validate).to be(false)
        expect(validator.errors.full_messages.first).to include("missing required qualifications")
      end

      it "passes when removed qualification is not required by any assigned ride's org" do
        org = create(:organization, required_qualifications: [])
        user = create(:user, role: UserRole::DRIVER)
        dq = DriverQualification.create!(user:, qualification: DriverQualification::QUALIFICATION_CWS_VETTED)
        ride_request = create(:ride_request, organization: org)
        create(:driver_assignment, ride_request:, driver: user)

        validator = described_class.new(removed_driver_qualifications: [ dq ])

        expect(validator.validate).to be(true)
      end

      it "passes when no qualifications are removed" do
        validator = described_class.new(removed_driver_qualifications: [])

        expect(validator.validate).to be(true)
      end
    end
  end
end
