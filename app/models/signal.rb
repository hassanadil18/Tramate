class TradeSignal < ApplicationRecord
    # Relationships
    belongs_to :channel
    has_many :trades, foreign_key: 'trade_signal_id', dependent: :destroy

    # Validations
    validates :message_content, presence: true
    validates :parsed_data, presence: true, if: :signal_processed?

  # Store parsed_data as JSON
  attribute :parsed_data, :json
  
  # Callbacks
  after_create :process_signal_async
  before_save :validate_parsed_data, if: :parsed_data_changed?
  
  # Scopes
  scope :valid_signals, -> { where.not(parsed_data: [nil, {}]) }
  scope :with_symbol, ->(symbol) { where("parsed_data->>'symbol' = ?", symbol.upcase) }
  scope :recent, -> { order(created_at: :desc) }
  scope :for_channel, ->(channel) { where(channel: channel) }
  
  # Methods to help with signal processing
  def process_signal
    # Use EnhancedSignalProcessor for better Discord signal parsing
    processor = EnhancedSignalProcessor.new(message_content)
    
    if processor.valid?
      self.parsed_data = processor.to_h
      self.confidence_score = processor.confidence_score
      self.signal_type = processor.signal_type.to_s
      self.status = 'processed'
      
      Rails.logger.info "Signal processed successfully: #{symbol} #{side} at #{entry_price}"
      save!
    else
      self.status = 'invalid'
      self.error_message = "Could not parse trading signal from message"
      save!
      Rails.logger.warn "Failed to process signal: #{message_content[0..100]}"
    end
  rescue => e
    self.status = 'error'
    self.error_message = "Error processing signal: #{e.message}"
    save!
    Rails.logger.error "Signal processing error: #{e.message}"
  end
  
  # Check if signal has been processed
  def signal_processed?
    parsed_data.present? && parsed_data['symbol'].present?
  end
  
  # Get trading symbol (e.g., "BTC")
  def symbol
    parsed_data&.dig('symbol') || parsed_data&.dig(:symbol)
  end
  
  # Get trading pair (e.g., "BTCUSDT")
  def trading_pair
    parsed_data&.dig('trading_pair') || parsed_data&.dig(:trading_pair) || "#{symbol}USDT"
  end
  
  # Get trade side (LONG/SHORT)
  def side
    parsed_data&.dig('side') || parsed_data&.dig(:side) || 'LONG'
  end
  
  # Get order side for Binance (BUY/SELL)
  def order_side
    parsed_data&.dig('order_side') || parsed_data&.dig(:order_side) || 'BUY'
  end
  
  # Get entry price
  def entry_price
    price = parsed_data&.dig('entry_price') || parsed_data&.dig(:entry_price)
    price.to_f if price
  end
  
  # Get take profit price
  def take_profit
    price = parsed_data&.dig('take_profit') || parsed_data&.dig(:take_profit)
    price.to_f if price
  end
  
  # Get stop loss price
  def stop_loss
    price = parsed_data&.dig('stop_loss') || parsed_data&.dig(:stop_loss)
    price.to_f if price
  end
  
  # Get multiple take profit levels
  def take_profit_levels
    levels = parsed_data&.dig('take_profit_levels') || parsed_data&.dig(:take_profit_levels)
    levels&.map(&:to_f) || [take_profit].compact
  end
  
  # Get risk/reward ratio
  def risk_reward_ratio
    ratio = parsed_data&.dig('risk_reward_ratio') || parsed_data&.dig(:risk_reward_ratio)
    ratio.to_f if ratio
  end
  
  # Get urgency level
  def urgency
    parsed_data&.dig('urgency') || parsed_data&.dig(:urgency) || 'low'
  end
  
  # Get recommended order type
  def recommended_order_type
    parsed_data&.dig('recommended_order_type') || parsed_data&.dig(:recommended_order_type) || 'LIMIT'
  end
  
  # Check if signal is urgent
  def urgent?
    urgency == 'high'
  end
  
  # Check if signal has good risk/reward ratio (>= 1.5)
  def good_risk_reward?
    risk_reward_ratio && risk_reward_ratio >= 1.5
  end
  
  # Get confidence score
  def confidence_score
    score = parsed_data&.dig('confidence_score') || parsed_data&.dig(:confidence_score)
    score.to_f if score
  end
  
  # Check if signal is high confidence (>= 0.8)
  def high_confidence?
    confidence_score && confidence_score >= 0.8
  end
  
  # Generate a summary of the signal
  def summary
    return "Invalid signal" unless signal_processed?
    
    summary_parts = []
    summary_parts << "#{symbol} #{side}"
    summary_parts << "Entry: #{entry_price}"
    summary_parts << "TP: #{take_profit}" if take_profit
    summary_parts << "SL: #{stop_loss}" if stop_loss
    summary_parts << "R/R: #{risk_reward_ratio}" if risk_reward_ratio
    
    summary_parts.join(" | ")
  end
  
  # Check if this signal can be traded (has minimum required data)
  def tradeable?
    signal_processed? && 
    symbol.present? && 
    entry_price.present? && 
    confidence_score && confidence_score >= 0.7
  end
  
  # Get the number of trades created from this signal
  def trades_count
    trades.count
  end
  
  # Get successful trades count
  def successful_trades_count
    trades.where(status: 'completed').count
  end
  
  # Calculate success rate for this signal
  def success_rate
    return 0 if trades_count == 0
    (successful_trades_count.to_f / trades_count * 100).round(2)
  end
  
  private
  
  def process_signal_async
    # Process signal in background if content is present
    ProcessSignalJob.perform_later(self.id) if message_content.present?
  end
  
  def validate_parsed_data
    return true unless parsed_data.present?
    
    # Validate that we have minimum required fields
    required_fields = ['symbol', 'entry_price']
    missing_fields = required_fields.select { |field| parsed_data[field].blank? && parsed_data[field.to_sym].blank? }
    
    if missing_fields.any?
      errors.add(:parsed_data, "missing required fields: #{missing_fields.join(', ')}")
      return false
    end
    
    # Validate price relationships
    entry = entry_price
    tp = take_profit
    sl = stop_loss
    signal_side = side
    
    if entry && tp && signal_side == 'LONG' && tp <= entry
      errors.add(:parsed_data, "take profit must be higher than entry price for LONG positions")
      return false
    end
    
    if entry && sl && signal_side == 'LONG' && sl >= entry
      errors.add(:parsed_data, "stop loss must be lower than entry price for LONG positions")
      return false
    end
    
    if entry && tp && signal_side == 'SHORT' && tp >= entry
      errors.add(:parsed_data, "take profit must be lower than entry price for SHORT positions")
      return false
    end
    
    if entry && sl && signal_side == 'SHORT' && sl <= entry
      errors.add(:parsed_data, "stop loss must be higher than entry price for SHORT positions")
      return false
    end
    
    true
  end
end
