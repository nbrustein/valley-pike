class CreateHumans < ActiveRecord::Migration[8.1]
  def change
    create_table :humans, id: :uuid do |t|
      t.references :user, null: false, foreign_key: true, type: :uuid, index: {unique: true}
      t.string :full_name, null: false
      t.string :phone
      t.string :sortable_name, null: false

      t.timestamps
    end
  end
end
