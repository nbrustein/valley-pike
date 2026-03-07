class CreateAddresses < ActiveRecord::Migration[8.1]
  def change
    create_table :addresses, id: :uuid do |t|
      t.string :name, null: false
      t.string :street_address, null: false
      t.string :city, null: false
      t.string :state, null: false
      t.string :zip, null: false
      t.string :country, null: false
      t.string :place_id
      t.decimal :latitude
      t.decimal :longitude

      t.timestamps
    end
  end
end
