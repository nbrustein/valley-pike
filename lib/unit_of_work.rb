class UnitOfWork
  attr_reader :executor_id, :params

  def self.execute(**)
    new(**).execute
  end

  def initialize(executor_id:, params:)
    @executor_id = executor_id
    @params = params
  end

  def execute
    execution = create_execution_record
    errors = ActiveModel::Errors.new(executor_for_errors)

    ActiveRecord::Base.transaction do
      begin
        ActiveRecord::Base.transaction(requires_new: true) do
          execute_unit_of_work(errors:)
          raise ActiveRecord::Rollback if errors.any?
        end
      rescue StandardError => error
        errors.add(:base, error.message)
      end

      execution.update!(
        completed_at: Time.current,
        result: errors.any? ? "failure" : "success"
      )
    end

    UnitOfWork::Result.new(errors:)
  end

  private

  attr_reader :executor_id, :params

  def create_execution_record
    UnitOfWorkExecution.create!(
      executor_id: audit_executor_id,
      unit_of_work: self.class.name,
      started_at: Time.current,
      params: audit_params
    )
  end

  def audit_executor_id
    executor_id
  end

  def audit_params
    params
  end

  def execute_unit_of_work(errors:)
    raise NotImplementedError, "#{self.class} must implement #execute_unit_of_work"
  end

  def executor_for_errors
    @executor_for_errors ||= User.find(executor_id)
  end
end
