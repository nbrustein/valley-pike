# In order to know when we should store audit records for units of work, we want to track
# when one unit of work is executed from within another unit of work. This module handles
# that tracking
class UnitOfWork
  module HasExecutionContext
    private

    def with_execution_context
      increase_execution_depth
      yield
    ensure
      decrease_execution_depth
    end

    def execution_depth
      Thread.current[:unit_of_work_execution_depth].to_i
    end

    def increase_execution_depth
      Thread.current[:unit_of_work_execution_depth] = execution_depth + 1
    end

    def decrease_execution_depth
      Thread.current[:unit_of_work_execution_depth] = execution_depth - 1
    end
  end
end
