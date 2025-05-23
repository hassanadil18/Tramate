class RenameSignalToTradeSignal < ActiveRecord::Migration[8.0]
  def change
    # Rename the signals table to trade_signals
    rename_table :signals, :trade_signals
    
    # Update foreign keys
    rename_column :trades, :signal_id, :trade_signal_id
  end
end
