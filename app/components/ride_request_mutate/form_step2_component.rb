module RideRequestMutate
  class FormStep2Component < FormStepComponent
    include Memery

    def initialize(form:, ride_request: nil)
      super(form:)
      @ride_request = ride_request
    end

    private

    memoize def ride_description_public_field
      Shared::TextareaFieldComponent.new(
        form: @form,
        field: :ride_description_public,
        label: "Provide information that a potential driver will need to know when deciding whether to volunteer for this ride",
        value: @ride_request&.ride_description_public,
        description: "Consider including information about the rider's English ability and any languages they speak.",
        placeholder: "We are looking for a ride for a single woman to a court appointment. The appointment is expected to take up to 3 hours. The driver can leave during the appointment, but will need to be accessible by phone so they can come back and pick up the rider whenever the appointment is complete.",
        required: true,
      )
    end
  end
end
