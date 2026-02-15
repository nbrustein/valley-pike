class UnitOfWork
  include UnitOfWork::HasExecutionContext

  attr_reader :executor_id, :params

  def self.execute(**)
    new(**).execute
  end

  def initialize(executor_id:, params:)
    @executor_id = executor_id
    @params = params
  end

  def execute
    with_execution_context do
      execution = create_execution_record if should_audit_execution?
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

        execution&.update!(
          completed_at: Time.current,
          result: errors.any? ? "failure" : "success"
        )
      end

      UnitOfWork::Result.new(errors:)
    end
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

  # We do not store execution records for units of work that are executed from within
  # another unit of work. Only the unit triggered at the top level is recorded.
  def should_audit_execution?
    execution_depth == 1
  end
end
