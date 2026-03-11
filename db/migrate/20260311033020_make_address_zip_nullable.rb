class MakeAddressZipNullable < ActiveRecord::Migration[8.1]
  def change
    change_column_null :addresses, :zip, true
  end
end
