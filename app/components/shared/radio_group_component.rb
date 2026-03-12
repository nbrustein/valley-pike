module Shared
  class RadioGroupComponent < ViewComponent::Base
    def initialize(name:, label:, options:, selected:, readonly: false, include_none_option: true, input_data_attr: nil)
      @name = name
      @label = label
      @options = options
      @selected = selected
      @readonly = readonly
      @include_none_option = include_none_option
      @input_data_attr = input_data_attr
    end

    private

    def id_prefix
      @name.gsub(/[\[\]]+/, "_").delete_suffix("_")
    end

    def selected_label
      return "None" if @selected.blank?

      @options.each do |option|
        value, label = Array(option)
        return label || value.humanize if value == @selected
      end
      @selected.humanize
    end
  end
end
