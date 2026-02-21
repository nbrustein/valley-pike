module HasForms
  def expect_radio_option(field_name:, value:, label_text:, input_id:)
    expect(response.body).to have_css("label[for='#{input_id}']", text: label_text)
    expect(response.body).to have_css("input##{input_id}[name='#{field_name}'][value='#{value}']")
  end
end
