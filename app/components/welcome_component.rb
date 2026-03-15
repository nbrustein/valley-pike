class WelcomeComponent < ViewComponent::Base
  def initialize(identity:)
    @identity = identity
  end

  def signed_in?
    @identity.present?
  end
end
