module AdminRideRequestMutate
  class FormStep2Component < FormStepComponent
    include Memery

    def initialize(form:, total_steps:, ride_request: nil)
      super(form:, total_steps:)
      @ride_request = ride_request
    end

    private

    memoize def pick_up_address_field
      Shared::AddressFieldsComponent.new(
        form: @form,
        field: :pick_up_address,
        label: "Pick Up Address",
        value: @ride_request&.pick_up_address,
        name_placeholder: "ex. Rider's Home",
        street_address_description: "The exact street address will only be sent to the driver who accepts the ride",
      )
    end

    memoize def destination_address_field
      Shared::AddressFieldsComponent.new(
        form: @form,
        field: :destination_address,
        label: "Destination Address",
        value: @ride_request&.destination_address,
        name_placeholder: "ex. UVA Hospital",
      )
    end

    memoize def ride_description_public_field
      Shared::TextareaFieldComponent.new(
        form: @form,
        field: :ride_description_public,
        value: @ride_request&.ride_description_public,
        placeholder: "We are looking for a ride for a single woman to a court appointment. The appointment is " \
          "expected to take up to 3 hours. The driver can leave during the appointment, but will need to be " \
          "accessible by phone so they can come back and pick up the rider whenever the appointment is complete.",
        required: true,
        rows: 6,
      )
    end
  end
end
