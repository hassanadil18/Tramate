class AddTrackingFieldsToTrades < ActiveRecord::Migration[8.0]
  def change
    add_column :trades, :pre_trade_data, :json
    add_column :trades, :post_trade_data, :json
    add_column :trades, :error_data, :json
    add_column :trades, :take_profit_data, :json
    add_column :trades, :stop_loss_data, :json
    add_column :trades, :needs_review, :boolean
    add_column :trades, :review_reason, :string
    add_column :trades, :review_requested_at, :datetime
  end
end
