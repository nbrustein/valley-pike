module FormHelpers
  # Capybara's fill_in doesn't work reliably with date inputs in headless browsers.
  # This helper sets the value via JavaScript instead.
  def fill_in_date(label, with:)
    field = find_field(label)
    execute_script("document.getElementById('#{field[:id]}').value = '#{with}'")
  end
end
