class AddProcessingFieldsToTradeSignals < ActiveRecord::Migration[8.0]
  def change
    add_column :trade_signals, :processed_at, :datetime
    add_column :trade_signals, :trades_created, :integer
  end
end
