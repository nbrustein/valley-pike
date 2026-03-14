module Shared
  class TextareaFieldComponent < ViewComponent::Base
    def initialize(form:, field:, label: nil, value: nil, readonly: false, required: false,
      description: nil, placeholder: nil, rows: nil)
      @form = form
      @field = field
      @label = label
      @value = value
      @readonly = readonly
      @required = required
      @description = description
      @placeholder = placeholder
      @rows = rows
    end
  end
end
