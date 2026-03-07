class CreateDriverAssignments < ActiveRecord::Migration[8.1]
  def change
    create_table :driver_assignments, id: :uuid do |t|
      t.references :ride_request, null: false, foreign_key: true, type: :uuid
      t.references :driver, null: false, foreign_key: {to_table: :users}, type: :uuid
      t.boolean :canceled, null: false, default: false

      t.timestamps
    end

    add_index :driver_assignments, %i[ride_request_id driver_id], unique: true
  end
end
