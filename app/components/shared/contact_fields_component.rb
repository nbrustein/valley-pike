module Shared
  class ContactFieldsComponent < ViewComponent::Base
    include Memery

    def initialize(form:, label:, full_name: nil, phone: nil, email: nil, readonly: false, required_name: false)
      @form = form
      @label = label
      @full_name = full_name
      @phone = phone
      @email = email
      @readonly = readonly
      @required_name = required_name
    end

    def formatted_contact_lines
      [
        @full_name,
        @phone,
        @email,
      ].select(&:present?)
    end

    private

    memoize def contact_full_name_field
      Shared::TextFieldComponent.new(
        form: @form,
        field: :contact_full_name,
        label: "Contact Name",
        value: @full_name,
        required: @required_name,
      )
    end

    memoize def contact_phone_field
      Shared::TextFieldComponent.new(
        form: @form,
        field: :contact_phone,
        label: "Contact Phone",
        value: @phone,
        type: :phone,
      )
    end

    memoize def contact_email_field
      Shared::TextFieldComponent.new(
        form: @form,
        field: :contact_email,
        label: "Contact Email",
        value: @email,
        type: :email,
      )
    end
  end
end
