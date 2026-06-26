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

ActiveRecord::Schema[8.1].define(version: 2026_06_23_144522) do
  create_table "coin_slot_sessions", force: :cascade do |t|
    t.integer "coin_slot_id", null: false
    t.datetime "created_at", null: false
    t.datetime "ended_at"
    t.integer "pc_id", null: false
    t.string "public_uid"
    t.datetime "started_at"
    t.integer "status", default: 0
    t.datetime "updated_at", null: false
    t.index ["coin_slot_id"], name: "index_coin_slot_sessions_on_coin_slot_id"
    t.index ["pc_id"], name: "index_coin_slot_sessions_on_pc_id"
  end

  create_table "coin_slots", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "device_id"
    t.string "ip_address"
    t.datetime "last_seen_at"
    t.string "mac_address"
    t.string "name"
    t.text "secret"
    t.integer "status", default: 0
    t.datetime "updated_at", null: false
    t.index ["device_id"], name: "index_coin_slots_on_device_id", unique: true
  end

  create_table "coin_transactions", force: :cascade do |t|
    t.integer "coin_slot_id", null: false
    t.datetime "created_at", null: false
    t.integer "minutes_granted"
    t.integer "pc_id", null: false
    t.integer "peso_amount"
    t.integer "status", default: 0
    t.string "transaction_uid"
    t.datetime "updated_at", null: false
    t.index ["coin_slot_id"], name: "index_coin_transactions_on_coin_slot_id"
    t.index ["pc_id"], name: "index_coin_transactions_on_pc_id"
  end

  create_table "command_logs", force: :cascade do |t|
    t.integer "coin_slot_id"
    t.integer "command"
    t.datetime "created_at", null: false
    t.string "error_message"
    t.datetime "executed_at"
    t.integer "pc_id"
    t.datetime "sent_at"
    t.integer "status"
    t.string "type"
    t.datetime "updated_at", null: false
    t.index ["coin_slot_id"], name: "index_command_logs_on_coin_slot_id"
    t.index ["pc_id"], name: "index_command_logs_on_pc_id"
  end

  create_table "pc_sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "expires_at"
    t.integer "pc_id", null: false
    t.string "public_uid"
    t.datetime "started_at"
    t.integer "status", default: 0
    t.integer "total_minutes_purchased"
    t.integer "total_minutes_used"
    t.datetime "updated_at", null: false
    t.index ["pc_id"], name: "index_pc_sessions_on_pc_id"
    t.index ["public_uid"], name: "index_pc_sessions_on_public_uid", unique: true
  end

  create_table "pcs", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "device_id"
    t.string "ip_address"
    t.datetime "last_seen_at"
    t.string "mac_address"
    t.string "name"
    t.text "secret"
    t.integer "status", default: 0
    t.datetime "updated_at", null: false
    t.index ["device_id"], name: "index_pcs_on_device_id", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.integer "role", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "coin_slot_sessions", "coin_slots"
  add_foreign_key "coin_slot_sessions", "pcs"
  add_foreign_key "coin_transactions", "coin_slots"
  add_foreign_key "coin_transactions", "pcs"
  add_foreign_key "command_logs", "coin_slots"
  add_foreign_key "command_logs", "pcs"
  add_foreign_key "pc_sessions", "pcs"
end
