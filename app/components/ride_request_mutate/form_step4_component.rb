module RideRequestMutate
  class FormStep4Component < FormStepComponent
    include Memery

    def initialize(form:, ride_request: nil, requester: nil)
      super(form:)
      @ride_request = ride_request
      @requester = requester
    end

    private

    memoize def contact_full_name_field
      Shared::TextFieldComponent.new(
        form: @form,
        field: :contact_full_name,
        label: "Contact Name",
        value: @ride_request&.contact_full_name || @requester&.human&.full_name,
        required: true,
      )
    end

    memoize def contact_phone_field
      Shared::TextFieldComponent.new(
        form: @form,
        field: :contact_phone,
        label: "Contact Phone",
        value: @ride_request&.contact_phone || @requester&.human&.phone,
        type: :phone,
      )
    end

    memoize def contact_email_field
      Shared::TextFieldComponent.new(
        form: @form,
        field: :contact_email,
        label: "Contact Email",
        value: @ride_request&.contact_email || @requester&.email,
        type: :email,
      )
    end
  end
end
