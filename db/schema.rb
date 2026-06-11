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

ActiveRecord::Schema[8.1].define(version: 2026_06_11_195213) do
  create_table "properties", force: :cascade do |t|
    t.string "city"
    t.string "country"
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name", null: false
    t.string "postal_code"
    t.integer "stars"
    t.string "street"
    t.datetime "updated_at", null: false
  end

  create_table "rooms", force: :cascade do |t|
    t.integer "capacity", null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.integer "floor"
    t.integer "nightly_rate_cents", default: 0, null: false
    t.string "number", null: false
    t.integer "property_id", null: false
    t.string "room_type", null: false
    t.string "status", default: "operational", null: false
    t.datetime "updated_at", null: false
    t.index ["property_id", "number"], name: "index_rooms_on_property_id_and_number", unique: true
    t.index ["property_id"], name: "index_rooms_on_property_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  add_foreign_key "rooms", "properties"
  add_foreign_key "sessions", "users"
end
