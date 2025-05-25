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

ActiveRecord::Schema[8.0].define(version: 2025_05_25_114849) do
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
    t.string "connection_type"
    t.string "account_type"
    t.boolean "can_trade"
    t.boolean "can_withdraw"
    t.datetime "validated_at"
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
    t.string "status", default: "active"
    t.string "channel_type", default: "discord"
    t.string "logo_url"
    t.string "signal_format", default: "standard"
    t.text "signal_template"
    t.string "webhook_url"
    t.string "api_key"
    t.string "discord_invite_link"
    t.string "discord_guild_id"
    t.string "discord_webhook_url"
    t.text "discord_bot_permissions"
    t.index ["channel_type"], name: "index_channels_on_channel_type"
    t.index ["discord_channel_id"], name: "index_channels_on_discord_channel_id", unique: true
    t.index ["discord_guild_id"], name: "index_channels_on_discord_guild_id"
    t.index ["signal_format"], name: "index_channels_on_signal_format"
    t.index ["status"], name: "index_channels_on_status"
  end

  create_table "notifications", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.text "message", null: false
    t.boolean "read", default: false
    t.string "notification_type"
    t.datetime "read_at"
    t.json "data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["read"], name: "index_notifications_on_read"
    t.index ["user_id"], name: "index_notifications_on_user_id"
  end

  create_table "payments", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.decimal "amount", precision: 10, scale: 2, null: false
    t.string "payment_gateway_id", null: false
    t.string "status", null: false
    t.datetime "status_updated_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "notes"
    t.index ["payment_gateway_id"], name: "index_payments_on_payment_gateway_id", unique: true
    t.index ["user_id"], name: "index_payments_on_user_id"
  end

  create_table "subscriptions", force: :cascade do |t|
    t.string "name"
    t.decimal "price", precision: 10, scale: 2, default: "0.0"
    t.text "description"
    t.integer "trade_limit"
    t.bigint "user_id"
    t.string "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_subscriptions_on_user_id"
  end

  create_table "system_logs", force: :cascade do |t|
    t.string "level", null: false
    t.text "message", null: false
    t.jsonb "context"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "source"
    t.index ["created_at"], name: "index_system_logs_on_created_at"
    t.index ["level"], name: "index_system_logs_on_level"
  end

  create_table "trade_signals", force: :cascade do |t|
    t.bigint "channel_id", null: false
    t.text "message_content", null: false
    t.json "parsed_data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "status", default: "pending"
    t.string "signal_type"
    t.decimal "confidence_score", precision: 5, scale: 3
    t.text "error_message"
    t.string "urgency"
    t.decimal "risk_reward_ratio", precision: 8, scale: 2
    t.datetime "processed_at"
    t.integer "trades_created"
    t.index "((parsed_data ->> 'symbol'::text))", name: "index_trade_signals_on_symbol"
    t.index ["channel_id"], name: "index_trade_signals_on_channel_id"
    t.index ["confidence_score"], name: "index_trade_signals_on_confidence_score"
    t.index ["signal_type"], name: "index_trade_signals_on_signal_type"
    t.index ["status"], name: "index_trade_signals_on_status"
  end

  create_table "trades", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "trade_signal_id", null: false
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
    t.index ["trade_signal_id"], name: "index_trades_on_trade_signal_id"
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
    t.integer "subscription_id"
    t.integer "trades_count"
    t.datetime "subscription_start_date"
    t.datetime "subscription_end_date"
    t.index ["binance_api_key"], name: "index_users_on_binance_api_key", unique: true
    t.index ["discord_id"], name: "index_users_on_discord_id", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "api_credentials", "users"
  add_foreign_key "notifications", "users"
  add_foreign_key "payments", "users"
  add_foreign_key "subscriptions", "users"
  add_foreign_key "trade_signals", "channels"
  add_foreign_key "trades", "trade_signals"
  add_foreign_key "trades", "users"
  add_foreign_key "user_channel_accesses", "channels"
  add_foreign_key "user_channel_accesses", "payments"
  add_foreign_key "user_channel_accesses", "users"
end
