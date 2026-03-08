module Shared
  class DateFieldComponent < ViewComponent::Base
    def initialize(form:, field:, label:, value:, readonly: false)
      @form = form
      @field = field
      @label = label
      @value = value
      @readonly = readonly
    end
  end
end
