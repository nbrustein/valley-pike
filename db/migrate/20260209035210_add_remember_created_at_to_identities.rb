class AddRememberCreatedAtToIdentities < ActiveRecord::Migration[8.1]
  def change
    add_column :identities, :remember_created_at, :datetime
  end
end
