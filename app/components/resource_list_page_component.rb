class ResourceListPageComponent < ViewComponent::Base
  def initialize(title:, create_path: nil)
    @title = title
    @create_path = create_path
  end
end
