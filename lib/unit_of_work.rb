class UnitOfWork
  class Result
    attr_reader :errors

    def initialize(errors:)
      unless errors.is_a?(ActiveModel::Errors)
        raise ArgumentError, "errors must be an instance of ActiveModel::Errors"
      end

      @errors = errors
    end

    def success?
      errors.empty?
    end
  end

  def self.execute(**)
    new(**).execute
  end
end
