module Shared
  class TextFieldComponent < ViewComponent::Base
    FIELD_METHODS = {text: :text_field, email: :email_field, phone: :phone_field}.freeze

    def initialize(form:, field:, label:, value:, readonly: false, required: false, type: :text, data: {}, description: nil, placeholder: nil)
      @form = form
      @field = field
      @label = label
      @value = value
      @readonly = readonly
      @required = required
      @type = type
      @data = data
      @description = description
      @placeholder = placeholder
    end

    private

    def field_method
      FIELD_METHODS.fetch(@type) { raise ArgumentError, "Unknown field type: #{@type.inspect}" }
    end
  end
end
