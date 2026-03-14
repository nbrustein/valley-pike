# FIXME: refactor so that callers don't have to wrap each cell in the row_path
class ResourceRowComponent < ViewComponent::Base
  def initialize(edit_path: nil, show_path: nil, data: {})
    @edit_path = edit_path
    @show_path = show_path
    @data = data
  end

  private

  def tr_attrs
    attrs = {class: tr_class}
    attrs[:data] = @data unless @data.empty?
    attrs
  end

  def tr_class
    base = "border-b border-primary/10 align-top"
    return base unless @edit_path || @show_path

    "#{base} cursor-pointer transition hover:opacity-85 active:opacity-70"
  end
end
