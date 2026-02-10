class CreateIdentities < ActiveRecord::Migration[8.1]
  def change
    create_table :identities, id: :uuid do |t|
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.string :kind, null: false
      t.string :email_normalized
      t.string :provider
      t.string :uid
      t.string :encrypted_password
      t.datetime :confirmed_at
      t.datetime :disabled_at
      t.datetime :last_used_at
      t.string :last_used_ip

      t.timestamps
    end

    add_index :identities, %i[kind email_normalized], unique: true, where: "email_normalized IS NOT NULL"
    add_index :identities, %i[provider uid], unique: true, where: "provider IS NOT NULL AND uid IS NOT NULL"
    add_check_constraint :identities, "kind IN ('magic_link', 'password', 'oauth')", name: "identities_kind_check"
  end
end
