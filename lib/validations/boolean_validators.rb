module Validations
  module BooleanValidators
    def validates_truth_of(*attrs)
      validates(*attrs, inclusion: {in: [ true ], message: "must be true"})
    end

    def validates_falsity_of(*attrs)
      validates(*attrs, inclusion: {in: [ false ], message: "must be false"})
    end
  end
end
