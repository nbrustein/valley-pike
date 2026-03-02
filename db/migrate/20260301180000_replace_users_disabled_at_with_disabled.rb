class ReplaceUsersDisabledAtWithDisabled < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :disabled, :boolean, null: false, default: false
    remove_column :users, :disabled_at, :datetime
  end
end
