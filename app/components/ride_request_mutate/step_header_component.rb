module RideRequestMutate
  class StepHeaderComponent < ViewComponent::Base
    def initialize(step:, total_steps:, title:, description:)
      @step = step
      @total_steps = total_steps
      @title = title
      @description = description
    end
  end
end
