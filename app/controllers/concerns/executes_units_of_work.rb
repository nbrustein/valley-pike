module ExecutesUnitsOfWork
  extend ActiveSupport::Concern

  def execute_unit_of_work(policy_meth: nil, policy_class: nil, &block)
    begin
      uow = yield
      authorize(uow, policy_meth, policy_class:) if policy_meth.present?
      result = uow.execute
      if result.success?
        return [true, result.errors]
      else
        @errors = result.errors
      end
    rescue Pundit::NotAuthorizedError
      raise
    rescue StandardError
      @errors = ActiveModel::Errors.new(nil)
      @errors.add(:base, "An error occurred")
    end

    return [false, @errors]
  end
end