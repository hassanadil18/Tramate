class TradeSignal < ApplicationRecord
  self.table_name = 'trade_signals'
  
  # Relationships
  belongs_to :channel
  has_many :trades, foreign_key: 'trade_signal_id'

  # Validations
  validates :message_content, presence: true

  # Store parsed_data as JSON
  attribute :parsed_data, :json

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

  # Methods to help with signal processing
  def process_signal
    # Parse the message_content to extract signal data
    parse_result = parse_message(message_content)

    if parse_result
      # Update the parsed_data attribute with extracted values
      self.parsed_data = parse_result
      self.save
    end
  end

  private

  def parse_message(content)
    # Initialize result hash
    result = {}

    # Extract coin name
    coin_match = content.match(/Coin:\s*(\w+)/)
    result[:coin] = coin_match[1] if coin_match

    # Extract take profit value
    tp_match = content.match(/TP:\s*([\d\.]+)/)
    result[:take_profit] = tp_match[1].to_f if tp_match

    # Extract stop loss value
    sl_match = content.match(/SL:\s*([\d\.]+)/)
    result[:stop_loss] = sl_match[1].to_f if sl_match

    # Extract entry price value
    ep_match = content.match(/EP:\s*([\d\.]+)/)
    result[:entry_price] = ep_match[1].to_f if ep_match

    # Only return the result if we found at least the coin and one price point
    result.present? && result[:coin].present? && (result[:take_profit].present? || result[:stop_loss].present? || result[:entry_price].present?) ? result : nil
  end
end 