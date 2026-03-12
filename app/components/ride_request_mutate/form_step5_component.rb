module RideRequestMutate
  class FormStep5Component < FormStepComponent
    include Memery
    include Concerns::HasOrganizationOptions
    include Concerns::HasDriverOptions

    def initialize(form:, total_steps:, ride_request: nil, organizations: [])
      super(form:, total_steps:)
      @ride_request = ride_request
      @organizations = organizations
    end

    private

    # Public fields

    memoize def organization_field
      Shared::SelectFieldComponent.new(
        form: @form,
        field: :organization_id,
        label: "Organization",
        options: organization_options,
        selected: @ride_request&.organization_id,
        readonly: true,
      )
    end

    memoize def short_description_field
      Shared::TextFieldComponent.new(
        form: @form,
        field: :short_description,
        label: "Short Description",
        value: @ride_request&.short_description,
        readonly: true,
      )
    end

    memoize def ride_date_field
      Shared::DateFieldComponent.new(
        form: @form,
        field: :date,
        label: "Ride Date",
        value: @ride_request&.date&.iso8601,
        readonly: true,
      )
    end

    memoize def driver_count_field
      Shared::RadioGroupComponent.new(
        name: "ride_request[requires_multiple_drivers]",
        label: "How many drivers do you need?",
        options: driver_count_options,
        selected: (@ride_request&.requires_multiple_drivers || false).to_s,
        readonly: true,
      )
    end

    memoize def driver_gender_field
      Shared::RadioGroupComponent.new(
        name: "ride_request[desired_driver_gender]",
        label: "Driver Gender Requirement",
        options: driver_gender_options,
        selected: @ride_request&.desired_driver_gender || "none",
        readonly: true,
      )
    end

    memoize def appointment_time_field
      Shared::TextFieldComponent.new(
        form: @form,
        field: :appointment_time,
        label: "Appointment Time",
        value: @ride_request&.appointment_time,
        readonly: true,
      )
    end

    memoize def ride_description_public_field
      Shared::TextareaFieldComponent.new(
        form: @form,
        field: :ride_description_public,
        label: "Public Description",
        value: @ride_request&.ride_description_public,
        readonly: true,
      )
    end

    memoize def contact_full_name_field
      Shared::TextFieldComponent.new(
        form: @form,
        field: :contact_full_name,
        label: "Contact Name",
        value: @ride_request&.contact_full_name,
        readonly: true,
      )
    end

    memoize def contact_phone_field
      Shared::TextFieldComponent.new(
        form: @form,
        field: :contact_phone,
        label: "Contact Phone",
        value: @ride_request&.contact_phone,
        readonly: true,
      )
    end

    memoize def contact_email_field
      Shared::TextFieldComponent.new(
        form: @form,
        field: :contact_email,
        label: "Contact Email",
        value: @ride_request&.contact_email,
        readonly: true,
      )
    end

    # Private fields

    memoize def ride_description_private_field
      Shared::TextareaFieldComponent.new(
        form: @form,
        field: :ride_description_private,
        label: "Private Ride Notes",
        value: @ride_request&.ride_description_private,
        readonly: true,
      )
    end
  end
end
