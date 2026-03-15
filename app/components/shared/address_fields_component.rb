module Shared
  class AddressFieldsComponent < ViewComponent::Base
    include Memery

    def initialize(form:, field:, label:, value: nil, readonly: false, street_address_description: nil)
      @form = form
      @field = field
      @label = label
      @value = value
      @readonly = readonly
      @street_address_description = street_address_description
    end

    def before_render
      return if @readonly

      @addr_form = nil
      @form.fields_for(@field, @value) {|f| @addr_form = f }
    end

    def formatted_address_lines
      return [] if @value.nil?

      lines = []
      lines << @value.name if @value.name.present?
      lines << @value.street_address if @value.street_address.present?
      city_state = [ @value.city, @value.state ].select(&:present?).join(", ")
      lines << city_state if city_state.present?
      lines
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
      attrs = {form: @addr_form, field: :street_address, label: "Street Address",
               value: @value&.street_address, required: true}
      attrs[:description] = @street_address_description if @street_address_description
      Shared::TextFieldComponent.new(**attrs)
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
        value: @value&.state || "VA", required: true,
      )
    end
  end
end
