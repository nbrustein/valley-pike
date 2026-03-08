module Shared
  class TextareaFieldComponent < ViewComponent::Base
    def initialize(form:, field:, label:, value:, readonly: false, required: false, description: nil, placeholder: nil)
      @form = form
      @field = field
      @label = label
      @value = value
      @readonly = readonly
      @required = required
      @description = description
      @placeholder = placeholder
    end
  end
end
