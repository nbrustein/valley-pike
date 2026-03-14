module Shared
  class SelectFieldComponent < ViewComponent::Base
    def initialize(form:, field:, label:, options:, selected: nil, readonly: false, required: false)
      @form = form
      @field = field
      @label = label
      @options = options
      @selected = selected
      @readonly = readonly
      @required = required
    end

    private

    def single_option?
      @options.length == 1
    end

    def displayed_label
      @options.find {|_l, v| v.to_s == @selected.to_s }&.first || @options.first&.first
    end
  end
end
