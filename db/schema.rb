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

ActiveRecord::Schema[8.1].define(version: 2026_02_09_035210) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pgcrypto"

  create_table "identities", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "confirmed_at"
    t.datetime "created_at", null: false
    t.datetime "disabled_at"
    t.string "email_normalized"
    t.string "encrypted_password"
    t.string "kind", null: false
    t.datetime "last_used_at"
    t.string "last_used_ip"
    t.string "provider"
    t.string "uid"
    t.datetime "updated_at", null: false
    t.uuid "user_id", null: false
    t.datetime "remember_created_at"
    t.index ["kind", "email_normalized"], name: "index_identities_on_kind_and_email_normalized", unique: true, where: "(email_normalized IS NOT NULL)"
    t.index ["provider", "uid"], name: "index_identities_on_provider_and_uid", unique: true, where: "((provider IS NOT NULL) AND (uid IS NOT NULL))"
    t.index ["user_id"], name: "index_identities_on_user_id"
    t.check_constraint "kind::text = ANY (ARRAY['magic_link'::character varying, 'password'::character varying, 'oauth'::character varying]::text[])", name: "identities_kind_check"
  end

  create_table "users", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "disabled_at"
    t.datetime "updated_at", null: false
  end

  add_foreign_key "identities", "users"
end
