module RideRequestMutate
  class FormStepComponent < ViewComponent::Base
    def initialize(form:, total_steps:)
      @form = form
      @total_steps = total_steps
    end
  end
end
