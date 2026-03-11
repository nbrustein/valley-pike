module Shared
  class AddressFieldsComponent < ViewComponent::Base
    include Memery

    def initialize(form:, field:, value: nil)
      @form = form
      @field = field
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

    memoize def zip_field
      Shared::TextFieldComponent.new(
        form: @addr_form, field: :zip, label: "ZIP Code",
        value: @value&.zip, required: true,
      )
    end

    memoize def country_field
      Shared::TextFieldComponent.new(
        form: @addr_form, field: :country, label: "Country",
        value: @value&.country || "US", required: true,
      )
    end
  end
end
