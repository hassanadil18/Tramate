class Signal < ApplicationRecord
    # Relationships
    belongs_to :channel
    has_many :trades

    # Validations
    validates :message_content, presence: true

  # Store parsed_data as JSON
  serialize :parsed_data, JSON

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
