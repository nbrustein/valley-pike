class ResourceListComponent < ViewComponent::Base
  def initialize(columns:)
    @columns = columns
  end
end
