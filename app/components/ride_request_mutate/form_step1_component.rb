module RideRequestMutate
  class FormStep1Component < FormStepComponent
    include Memery

    def initialize(form:, organizations:, ride_request: nil)
      super(form:)
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
        description: "Used as the email subject line: 'Ride Requested: {your description}'",
      )
    end

    memoize def appointment_time_field
      Shared::TextFieldComponent.new(
        form: @form,
        field: :appointment_time,
        label: "Appointment / Timing",
        value: @ride_request&.appointment_time,
        description: "Enter a specific time if there is an appointment, or describe " \
          "timing requirements for potential drivers " \
          "(e.g. 'The rider can arrive any time between 9am and 12pm')",
      )
    end

    memoize def driver_count_field
      Shared::RadioGroupComponent.new(
        name: "ride_request[requires_multiple_drivers]",
        label: "Number of Drivers",
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
      )
    end

    memoize def organization_field
      Shared::SelectFieldComponent.new(
        form: @form,
        field: :organization_id,
        label: "Organization",
        options: organization_options,
        selected: @ride_request&.organization_id,
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
