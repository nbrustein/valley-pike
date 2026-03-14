module RideRequestMutate
  class StepHeaderComponent < ViewComponent::Base
    PUBLIC_DESCRIPTION = "This information will be sent to all eligible drivers"
    PRIVATE_DESCRIPTION = "This information will only be sent to the driver who accepts the ride"

    def initialize(step:, total_steps:, title:, description:)
      @step = step
      @total_steps = total_steps
      @title = title
      @description = description
    end
  end
end
