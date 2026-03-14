class MultiPageFormComponent < ViewComponent::Base
  # previous_path: omit (or pass nil) to hide the Previous button (e.g. first page)
  # last_page_label: defaults to "Submit"; override on the last page (e.g. "Publish")
  def initialize(page_paths:, current_page:, last_page_label: "Submit", delete_path: nil)
    @page_paths = page_paths
    @current_page = current_page
    @last_page_label = last_page_label
    @delete_path = delete_path
  end

  private

  def previous_path
    return nil if @current_page <= 1

    @page_paths[@current_page - 2]
  end

  def last_page?
    @current_page == @page_paths.length
  end

  def next_button_label
    last_page? ? @last_page_label : "Save and Continue"
  end
end
