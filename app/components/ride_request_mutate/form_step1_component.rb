module RideRequestMutate
  class FormStep1Component < FormStepComponent
    include Memery

    def initialize(form:, total_steps:, organizations:, ride_request: nil)
      super(form:, total_steps:)
      @organizations = organizations
      @ride_request = ride_request
    end

    private

    memoize def short_description_field
      Shared::TextFieldComponent.new(
        form: @form,
        field: :short_description,
        label: "Short Description",
        value: @ride_request&.short_description,
        description: "Used in the subject line for the email that goes to drivers.",
        placeholder: "Richmond Doctor Appt",
        required: true,
      )
    end

    memoize def appointment_time_field
      Shared::TextFieldComponent.new(
        form: @form,
        field: :appointment_time,
        label: "Appointment Time",
        value: @ride_request&.appointment_time,
        description: "If there is an appointment, enter a specific time. If not, tell potential drivers what the " \
          "requirements are. (e.g. 'The rider can arrive any time between 9am and 12pm')",
        placeholder: "9:00am",
        required: true,
      )
    end

    memoize def driver_count_field
      Shared::RadioGroupComponent.new(
        name: "ride_request[requires_multiple_drivers]",
        label: "How many drivers do you need?",
        options: driver_count_options,
        selected: (@ride_request&.requires_multiple_drivers || false).to_s,
        include_none_option: false,
      )
    end

    memoize def driver_gender_field
      Shared::RadioGroupComponent.new(
        name: "ride_request[desired_driver_gender]",
        label: "Driver Gender Requirement",
        options: driver_gender_options,
        selected: @ride_request&.desired_driver_gender || "none",
        include_none_option: false,
      )
    end

    memoize def ride_date_field
      Shared::DateFieldComponent.new(
        form: @form,
        field: :date,
        label: "Ride Date",
        value: @ride_request&.date&.iso8601,
        required: true,
      )
    end

    memoize def organization_field
      Shared::SelectFieldComponent.new(
        form: @form,
        field: :organization_id,
        label: "Organization",
        options: organization_options,
        selected: @ride_request&.organization_id,
        required: true,
      )
    end

    memoize def organization_options
      @organizations.map {|org| [ org.name, org.id ] }.freeze
    end

    memoize def driver_count_options
      [ [ "false", "1 Driver" ], [ "true", "Multiple Drivers" ] ].freeze
    end

    memoize def driver_gender_options
      [
        [ "none", "None" ],
        [ "female", "Female Driver" ],
        [ "female_accompaniment", "Female Accompaniment if Driver is Male" ],
  ].freeze
    end
  end
end
