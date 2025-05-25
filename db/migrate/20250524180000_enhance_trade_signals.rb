class EnhanceTradeSignals < ActiveRecord::Migration[8.0]
  def change
    # Add new fields for enhanced signal processing
    add_column :trade_signals, :status, :string, default: 'pending'
    add_column :trade_signals, :signal_type, :string
    add_column :trade_signals, :confidence_score, :decimal, precision: 5, scale: 3
    add_column :trade_signals, :error_message, :text
    add_column :trade_signals, :urgency, :string
    add_column :trade_signals, :risk_reward_ratio, :decimal, precision: 8, scale: 2
    
    # Add indices for better performance
    add_index :trade_signals, :status
    add_index :trade_signals, :signal_type
    add_index :trade_signals, :confidence_score
    add_index :trade_signals, "(parsed_data->>'symbol')", name: 'index_trade_signals_on_symbol'
  end
end 