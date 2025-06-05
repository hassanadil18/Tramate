class Trade < ApplicationRecord
  # Relationships
  belongs_to :user
  belongs_to :trade_signal, optional: true, foreign_key: 'trade_signal_id'

  # Modern JSON attributes
  attribute :pre_trade_data, :json
  attribute :post_trade_data, :json
  attribute :error_data, :json
  attribute :take_profit_data, :json
  attribute :stop_loss_data, :json


  # Validations
  validates :user_id, presence: true
  validates :status, presence: true, inclusion: { in: ['pending', 'executed', 'completed', 'failed', 'cancelled'] }
  validates :amount, numericality: { greater_than: 0 }, allow_nil: true

  # Scopes
  scope :completed, -> { where(status: "completed") }
  scope :executed, -> { where(status: "executed") }
  scope :pending, -> { where(status: "pending") }
  scope :failed, -> { where(status: "failed") }
  scope :skipped, -> { where(status: "skipped") }
  scope :recent, -> { order(created_at: :desc) }
  scope :this_week, -> { where("created_at > ?", 1.week.ago) }
  scope :by_symbol, ->(symbol) { joins(:trade_signal).where("trade_signals.parsed_data->>'symbol' = ?", symbol.upcase) }

  # Callbacks
  before_create :set_timestamp
  
  # Class methods for export
  def self.to_csv
    require 'csv'
    
    CSV.generate(headers: true) do |csv|
      # Define headers
      csv << [
        'ID', 'User', 'Status', 'Symbol', 'Amount', 
        'Signal ID', 'Execution Price', 'Created At'
      ]
      
      # Add data rows
      all.includes(:user).each do |trade|
        csv << [
          trade.id,
          trade.user&.email || 'Unknown',
          trade.status.capitalize,
          trade.symbol,
          trade.amount,
          trade.trade_signal_id,
          trade.execution_price,
          trade.created_at.strftime("%Y-%m-%d %H:%M")
        ]
      end
    end
  end

  # Returns trades with issues that admin should review
  def self.needs_review
    where("status = 'failed' OR (status = 'executed' AND notes LIKE '%error%')")
  end

  # Calculate profit/loss of completed trade
  def profit_loss
    return nil unless status == "completed" && execution_price.present? && exit_price.present?

    pl = if order_side == "BUY"
      ((exit_price - execution_price) / execution_price) * 100
    else
      ((execution_price - exit_price) / execution_price) * 100
    end

    pl.round(2)
  end

  # Determine if trade executed correctly compared to signal
  def matches_signal?
    return false unless trade_signal && trade_signal.parsed_data.present?

    # Check if the symbol, price range matches what we expected
    correct_symbol = symbol.to_s.downcase == trade_signal.symbol.to_s.downcase
    price_within_range = execution_price &&
                        (execution_price >= trade_signal.entry_price.to_f * 0.98) &&
                        (execution_price <= trade_signal.entry_price.to_f * 1.02)

    correct_symbol && price_within_range
  end

  # For admin to manually mark a trade for review
  def flag_for_review(reason)
    update(
      needs_review: true,
      review_reason: reason,
      review_requested_at: Time.current
    )
  end

  # Methods
  def successful?
    status == 'completed'
  end
  
  def failed?
    status == 'failed'
  end
  
  def pending?
    status == 'pending'
  end

  # Get symbol from trade signal
  def symbol
    trade_signal&.symbol || 'UNKNOWN'
  end

  # Get trading pair from trade signal
  def trading_pair
    trade_signal&.trading_pair || "#{symbol}USDT"
  end

  # Get trade type from trade signal
  def trade_type
    trade_signal&.side || 'LONG'
  end

  # Get order side from trade signal
  def order_side
    trade_signal&.order_side || 'BUY'
  end

  # Get entry price from trade signal
  def entry_price
    trade_signal&.entry_price || 0
  end

  # Get target price from trade signal
  def target_price
    trade_signal&.take_profit || 0
  end

  # Get stop loss from trade signal
  def stop_loss
    trade_signal&.stop_loss || 0
  end

  # Execution price (can be stored in pre_trade_data or as a separate field)
  def execution_price
    pre_trade_data&.dig('execution_price') || 0
  end

  def execution_price=(price)
    self.pre_trade_data ||= {}
    self.pre_trade_data['execution_price'] = price.to_f
  end

  # Executed quantity
  def executed_quantity
    pre_trade_data&.dig('executed_quantity') || amount || 0
  end

  def executed_quantity=(qty)
    self.pre_trade_data ||= {}
    self.pre_trade_data['executed_quantity'] = qty.to_f
  end

  # Exit price for completed trades
  def exit_price
    post_trade_data&.dig('exit_price') || 0
  end

  def exit_price=(price)
    self.post_trade_data ||= {}
    self.post_trade_data['exit_price'] = price.to_f
  end

  # Binance order ID
  def binance_order_id
    pre_trade_data&.dig('binance_order_id') || binance_trade_id
  end

  def binance_order_id=(order_id)
    self.pre_trade_data ||= {}
    self.pre_trade_data['binance_order_id'] = order_id.to_s
  end

  # Executed at timestamp
  def executed_at
    pre_trade_data&.dig('executed_at')&.to_time || timestamp
  end

  def executed_at=(time)
    self.pre_trade_data ||= {}
    self.pre_trade_data['executed_at'] = time.to_s
  end

  # Completed at timestamp
  def completed_at
    post_trade_data&.dig('completed_at')&.to_time
  end

  def completed_at=(time)
    self.post_trade_data ||= {}
    self.post_trade_data['completed_at'] = time.to_s
  end

  # Error message
  def error_message
    error_data&.dig('message') || error_data&.dig('error_message')
  end

  def error_message=(message)
    self.error_data ||= {}
    self.error_data['message'] = message.to_s
  end

  # Exit reason
  def exit_reason
    post_trade_data&.dig('exit_reason')
  end

  def exit_reason=(reason)
    self.post_trade_data ||= {}
    self.post_trade_data['exit_reason'] = reason.to_s
  end

  # Price method for dashboard display (alias for execution_price)
  def price
    execution_price
  end

  private

  def set_timestamp
    self.timestamp ||= Time.current
  end
end
