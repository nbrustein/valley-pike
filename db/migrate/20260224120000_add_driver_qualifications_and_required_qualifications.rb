class AddDriverQualificationsAndRequiredQualifications < ActiveRecord::Migration[8.1]
  def up
    create_table :driver_qualifications, id: :uuid do |t|
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.string :qualification, null: false

      t.timestamps
    end

    add_index :driver_qualifications, %i[user_id qualification], unique: true
    add_check_constraint :driver_qualifications,
                         "qualification IN ('cws_vetted')",
                         name: "driver_qualifications_qualification_check"

    add_column :organizations, :required_qualifications, :text, array: true, null: false, default: []
    execute <<~SQL
      UPDATE organizations
      SET required_qualifications = CASE
        WHEN require_vetted_drivers THEN ARRAY['cws_vetted']::text[]
        ELSE ARRAY[]::text[]
      END
    SQL
    remove_column :organizations, :require_vetted_drivers, :boolean
    add_check_constraint :organizations,
                         "required_qualifications <@ ARRAY['cws_vetted']::text[]",
                         name: "organizations_required_qualifications_check"

    execute <<~SQL
      UPDATE user_roles
      SET organization_id = NULL
      WHERE role = 'driver'
    SQL
    remove_check_constraint :user_roles, name: "user_roles_organization_id_check"
    add_check_constraint :user_roles,
      "(role IN ('developer', 'vanita_admin', 'vanita_viewer', 'driver') AND organization_id IS NULL) OR " \
      "(role IN ('org_admin', 'ride_requester') AND organization_id IS NOT NULL)",
      name: "user_roles_organization_id_check"
  end

  def down
    remove_check_constraint :user_roles, name: "user_roles_organization_id_check"
    add_check_constraint :user_roles,
                         "(role IN ('developer', 'vanita_admin', 'vanita_viewer') AND organization_id IS NULL) OR " \
                         "(role IN ('org_admin', 'ride_requester') AND organization_id IS NOT NULL) OR " \
                         "(role = 'driver')",
                         name: "user_roles_organization_id_check"

    remove_check_constraint :organizations, name: "organizations_required_qualifications_check"
    add_column :organizations, :require_vetted_drivers, :boolean, null: false, default: false
    execute <<~SQL
      UPDATE organizations
      SET require_vetted_drivers = CASE
        WHEN required_qualifications <@ ARRAY['cws_vetted']::text[] AND required_qualifications != ARRAY[]::text[] THEN TRUE
        ELSE FALSE
      END
    SQL
    remove_column :organizations, :required_qualifications

    remove_check_constraint :driver_qualifications, name: "driver_qualifications_qualification_check"
    drop_table :driver_qualifications
  end
end
