module AdminRideRequestMutate
  class FormStep4Component < FormStepComponent
    include Memery

    def initialize(form:, total_steps:, ride_request: nil, requester: nil)
      super(form:, total_steps:)
      @ride_request = ride_request
      @requester = requester
    end

    private

    memoize def contact_fields
      Shared::ContactFieldsComponent.new(
        form: @form,
        label: "Contact",
        full_name: @ride_request&.contact_full_name || @requester&.human&.full_name,
        phone: @ride_request&.contact_phone || @requester&.human&.phone,
        email: @ride_request&.contact_email || @requester&.email,
        required_name: true,
      )
    end
  end
end
