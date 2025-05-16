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

ActiveRecord::Schema[8.0].define(version: 2025_05_16_151324) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "api_credentials", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "platform"
    t.string "api_key"
    t.string "api_secret"
    t.string "ip_restriction"
    t.string "label"
    t.boolean "active"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_api_credentials_on_user_id"
  end

  create_table "channels", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.decimal "price_per_month", precision: 10, scale: 2
    t.string "discord_channel_id", null: false
    t.boolean "tramate_resell_enabled", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["discord_channel_id"], name: "index_channels_on_discord_channel_id", unique: true
  end

  create_table "payments", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.decimal "amount", precision: 10, scale: 2, null: false
    t.string "payment_gateway_id", null: false
    t.string "status", null: false
    t.datetime "status_updated_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["payment_gateway_id"], name: "index_payments_on_payment_gateway_id", unique: true
    t.index ["user_id"], name: "index_payments_on_user_id"
  end

  create_table "signals", force: :cascade do |t|
    t.bigint "channel_id", null: false
    t.text "message_content", null: false
    t.json "parsed_data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["channel_id"], name: "index_signals_on_channel_id"
  end

  create_table "system_logs", force: :cascade do |t|
    t.string "level", null: false
    t.text "message", null: false
    t.jsonb "context"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_system_logs_on_created_at"
    t.index ["level"], name: "index_system_logs_on_level"
  end

  create_table "trades", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "signal_id", null: false
    t.string "binance_trade_id"
    t.string "status", null: false
    t.decimal "amount", precision: 15, scale: 8
    t.datetime "timestamp"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.json "pre_trade_data"
    t.json "post_trade_data"
    t.json "error_data"
    t.json "take_profit_data"
    t.json "stop_loss_data"
    t.boolean "needs_review"
    t.string "review_reason"
    t.datetime "review_requested_at"
    t.index ["binance_trade_id"], name: "index_trades_on_binance_trade_id", unique: true
    t.index ["signal_id"], name: "index_trades_on_signal_id"
    t.index ["user_id"], name: "index_trades_on_user_id"
  end

  create_table "user_channel_accesses", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "channel_id", null: false
    t.string "access_type", null: false
    t.bigint "payment_id"
    t.datetime "access_start_date", null: false
    t.datetime "access_end_date", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["channel_id"], name: "index_user_channel_accesses_on_channel_id"
    t.index ["payment_id"], name: "index_user_channel_accesses_on_payment_id"
    t.index ["user_id", "channel_id"], name: "index_user_channel_accesses_on_user_id_and_channel_id", unique: true
    t.index ["user_id"], name: "index_user_channel_accesses_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", null: false
    t.string "password_digest", null: false
    t.string "discord_id"
    t.string "binance_api_key"
    t.string "encrypted_binance_api_secret"
    t.string "binance_api_secret_iv"
    t.string "subscription_status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "full_name"
    t.boolean "admin", default: false
    t.index ["binance_api_key"], name: "index_users_on_binance_api_key", unique: true
    t.index ["discord_id"], name: "index_users_on_discord_id", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "api_credentials", "users"
  add_foreign_key "payments", "users"
  add_foreign_key "signals", "channels"
  add_foreign_key "trades", "signals"
  add_foreign_key "trades", "users"
  add_foreign_key "user_channel_accesses", "channels"
  add_foreign_key "user_channel_accesses", "payments"
  add_foreign_key "user_channel_accesses", "users"
end
