# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_02_14_130000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pgcrypto"

  create_table "humans", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "full_name", null: false
    t.string "phone"
    t.string "sortable_name", null: false
    t.datetime "updated_at", null: false
    t.uuid "user_id", null: false
    t.index ["user_id"], name: "index_humans_on_user_id", unique: true
  end

  create_table "identities", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "confirmed_at"
    t.datetime "created_at", null: false
    t.datetime "disabled_at"
    t.string "email"
    t.string "encrypted_password"
    t.string "kind", null: false
    t.datetime "last_used_at"
    t.string "last_used_ip"
    t.string "provider"
    t.datetime "remember_created_at"
    t.string "uid"
    t.datetime "updated_at", null: false
    t.uuid "user_id"
    t.index ["kind", "email"], name: "index_identities_on_kind_and_email", unique: true, where: "(email IS NOT NULL)"
    t.index ["provider", "uid"], name: "index_identities_on_provider_and_uid", unique: true, where: "((provider IS NOT NULL) AND (uid IS NOT NULL))"
    t.index ["user_id"], name: "index_identities_on_user_id"
    t.check_constraint "kind::text = ANY (ARRAY['magic_link'::character varying::text, 'password'::character varying::text, 'oauth'::character varying::text])", name: "identities_kind_check"
  end

  create_table "organizations", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "abbreviation", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.boolean "require_vetted_drivers", default: false, null: false
    t.datetime "updated_at", null: false
  end

  create_table "unit_of_work_executions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "completed_at", precision: nil
    t.datetime "created_at", null: false
    t.uuid "executor_id", null: false
    t.json "params", default: {}, null: false
    t.text "result"
    t.datetime "started_at", precision: nil, null: false
    t.text "unit_of_work", null: false
    t.datetime "updated_at", null: false
    t.index ["executor_id"], name: "index_unit_of_work_executions_on_executor_id"
    t.check_constraint "result = ANY (ARRAY['failure'::text, 'success'::text])", name: "unit_of_work_executions_result_check"
  end

  create_table "user_roles", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.uuid "organization_id"
    t.string "role", null: false
    t.datetime "updated_at", null: false
    t.uuid "user_id", null: false
    t.index ["organization_id"], name: "index_user_roles_on_organization_id"
    t.index ["user_id"], name: "index_user_roles_on_user_id"
    t.check_constraint "role::text = ANY (ARRAY['developer'::character varying, 'vanita_admin'::character varying, 'org_admin'::character varying, 'driver'::character varying]::text[])", name: "user_roles_role_check"
  end

  create_table "users", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "disabled_at"
    t.string "email"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "humans", "users"
  add_foreign_key "identities", "users"
  add_foreign_key "unit_of_work_executions", "users", column: "executor_id"
  add_foreign_key "user_roles", "organizations"
  add_foreign_key "user_roles", "users"
end
