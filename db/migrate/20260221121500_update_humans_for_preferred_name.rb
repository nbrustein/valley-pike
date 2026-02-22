class UpdateHumansForPreferredName < ActiveRecord::Migration[8.1]
  def up
    add_column :humans, :preferred_name, :text, null: false, default: ""

    execute <<~SQL.squish
      UPDATE humans
      SET preferred_name = full_name
    SQL

    change_column_default :humans, :preferred_name, nil

    remove_column :humans, :sortable_name, :string
    remove_column :humans, :given_name, :text
  end

  def down
    add_column :humans, :sortable_name, :string, null: false, default: ""
    add_column :humans, :given_name, :text, null: false, default: ""

    execute <<~SQL.squish
      UPDATE humans
      SET sortable_name = full_name,
          given_name = full_name
    SQL

    change_column_default :humans, :sortable_name, nil
    change_column_default :humans, :given_name, nil

    remove_column :humans, :preferred_name, :text
  end
end
