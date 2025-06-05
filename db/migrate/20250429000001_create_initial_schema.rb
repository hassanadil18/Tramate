class CreateInitialSchema < ActiveRecord::Migration[8.0]
  def change
    # Create Users table
    create_table :users do |t|
      t.string :email, null: false
      t.string :password_digest, null: false
      t.string :discord_id
      t.string :binance_api_key
      t.string :encrypted_binance_api_secret
      t.string :binance_api_secret_iv # For attr_encrypted
      t.string :subscription_status
      
      t.timestamps
    end
    add_index :users, :email, unique: true
  
    add_index :users, :discord_id, unique: true
    add_index :users, :binance_api_key, unique: true

    # Create Channels table
    create_table :channels do |t|
      t.string :name, null: false
      t.text :description
      t.decimal :price_per_month, precision: 10, scale: 2
      t.string :discord_channel_id, null: false
      t.boolean :tramate_resell_enabled, default: false
      
      t.timestamps
    end
    add_index :channels, :discord_channel_id, unique: true

    # Create Signals table
    create_table :signals do |t|
      t.references :channel, null: false, foreign_key: true
      t.text :message_content, null: false
      t.json :parsed_data
      
      t.timestamps
    end

    # Create Trades table
    create_table :trades do |t|
      t.references :user, null: false, foreign_key: true
      t.references :signal, null: false, foreign_key: true
      t.string :binance_trade_id
      t.string :status, null: false
      t.decimal :amount, precision: 15, scale: 8
      t.datetime :timestamp
      
      t.timestamps
    end
    add_index :trades, :binance_trade_id, unique: true

    # Create Payments table
    create_table :payments do |t|
      t.references :user, null: false, foreign_key: true
      t.decimal :amount, precision: 10, scale: 2, null: false
      t.string :payment_gateway_id, null: false
      t.string :status, null: false
      t.datetime :status_updated_at
      
      t.timestamps
    end
    add_index :payments, :payment_gateway_id, unique: true

    # Create UserChannelAccess table
    create_table :user_channel_accesses do |t|
      t.references :user, null: false, foreign_key: true
      t.references :channel, null: false, foreign_key: true
      t.string :access_type, null: false
      t.references :payment, foreign_key: true
      t.datetime :access_start_date, null: false
      t.datetime :access_end_date, null: false
      
      t.timestamps
    end
    add_index :user_channel_accesses, [:user_id, :channel_id], unique: true
  end
end