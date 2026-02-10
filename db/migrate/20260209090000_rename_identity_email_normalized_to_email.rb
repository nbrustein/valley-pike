class RenameIdentityEmailNormalizedToEmail < ActiveRecord::Migration[8.1]
  def change
    remove_index :identities, [ :kind, :email_normalized ]
    rename_column :identities, :email_normalized, :email
    add_index :identities, [ :kind, :email ], unique: true, where: "email IS NOT NULL"
  end
end
