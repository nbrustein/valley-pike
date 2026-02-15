class CreateUnitOfWorkExecutions < ActiveRecord::Migration[8.1]
  def change
    create_table :unit_of_work_executions, id: :uuid do |t|
      t.references :executor, null: false, foreign_key: {to_table: :users}, type: :uuid
      t.text :unit_of_work, null: false
      t.timestamp :started_at, null: false
      t.timestamp :completed_at
      t.json :params, null: false, default: {}
      t.text :result

      t.timestamps
    end

    add_check_constraint :unit_of_work_executions,
                         "result IN ('failure', 'success')",
                         name: "unit_of_work_executions_result_check"
  end
end
