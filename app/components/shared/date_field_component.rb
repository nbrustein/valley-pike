module Shared
  class DateFieldComponent < ViewComponent::Base
    def initialize(form:, field:, label:, value:, readonly: false, required: false)
      @form = form
      @field = field
      @label = label
      @value = value
      @readonly = readonly
      @required = required
    end
  end
end
