module Shared
  class AddressFieldsComponent < ViewComponent::Base
    include Memery

    def initialize(form:, field:, label:, value: nil)
      @form = form
      @field = field
      @label = label
      @value = value
    end

    def before_render
      @addr_form = nil
      @form.fields_for(@field, @value) {|f| @addr_form = f }
    end

    private

    memoize def name_field
      Shared::TextFieldComponent.new(
        form: @addr_form, field: :name, label: "Name", value: @value&.name,
        description: "Name or description of the location (e.g. Kaiser Permanente, Home)",
        required: true,
      )
    end

    memoize def street_address_field
      Shared::TextFieldComponent.new(
        form: @addr_form, field: :street_address, label: "Street Address",
        value: @value&.street_address, required: true,
      )
    end

    memoize def city_field
      Shared::TextFieldComponent.new(
        form: @addr_form, field: :city, label: "City",
        value: @value&.city, required: true,
      )
    end

    memoize def state_field
      Shared::TextFieldComponent.new(
        form: @addr_form, field: :state, label: "State",
        value: @value&.state, required: true,
      )
    end
  end
end
