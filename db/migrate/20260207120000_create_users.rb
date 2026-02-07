class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users, id: :uuid do |t|
      t.datetime :disabled_at

      t.timestamps
    end
  end
end
