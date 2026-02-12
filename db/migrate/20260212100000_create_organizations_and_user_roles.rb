class CreateOrganizationsAndUserRoles < ActiveRecord::Migration[8.1]
  def change
    create_table :organizations, id: :uuid do |t|
      t.string :name, null: false
      t.string :abbreviation, null: false
      t.boolean :require_vetted_drivers, null: false, default: false

      t.timestamps
    end

    create_table :user_roles, id: :uuid do |t|
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.references :organization, null: true, foreign_key: true, type: :uuid
      t.string :role, null: false

      t.timestamps
    end

    add_check_constraint :user_roles,
                         "role IN ('developer', 'vanita_admin', 'org_admin', 'driver')",
                         name: "user_roles_role_check"
  end
end
