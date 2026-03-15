module AdminRideRequestMutate
  class FormStep3Component < FormStepComponent
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
      )
    end

    memoize def ride_description_private_field
      Shared::TextareaFieldComponent.new(
        form: @form,
        field: :ride_description_private,
        value: @ride_request&.ride_description_private,
        rows: 4,
      )
    end
  end
end
