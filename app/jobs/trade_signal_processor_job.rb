class TradeSignalProcessorJob < ApplicationJob
  queue_as :default

  def perform(channel_id, discord_message_data)
    channel = Channel.find(channel_id)
    message_content = discord_message_data['content']
    author = discord_message_data['author']
    
    # Log the received message
    SystemLog.log_info("Processing Discord trading signal", {
      channel_id: channel_id,
      channel_name: channel.name,
      message: message_content,
      author: author['username']
    })
    
    # Parse the trading signal
    signal_data = parse_trading_signal(message_content)
    
    if signal_data.nil?
      SystemLog.log_error("Failed to parse trading signal", {
        channel_id: channel_id,
        message: message_content
      })
      return
    end
    
    # Create TradeSignal record
    trade_signal = TradeSignal.create!(
      channel: channel,
      message_content: message_content,
      parsed_data: signal_data,
      status: 'pending',
      created_at: Time.current
    )
    
    SystemLog.log_info("Created TradeSignal #{trade_signal.id} for channel #{channel.name}", {
      signal_id: trade_signal.id,
      symbol: signal_data[:symbol],
      side: signal_data[:side],
      entry_price: signal_data[:entry_price]
    })
    
    # Execute the trade signal using existing job
    ExecuteTradeJob.perform_later(trade_signal.id)
  end

  private

  def parse_trading_signal(content)
    # Enhanced signal parsing to handle multiple formats
    signal_data = {}
    
    # Extract trading pair - handle markdown formatting
    pair_match = content.match(/(?:pair|symbol).*?([A-Z]{3,10}USDT?)/i) ||
                content.match(/\b([A-Z]{3,10}USDT?)\b/)
    return nil unless pair_match
    
    symbol = pair_match[1].upcase
    symbol += 'USDT' unless symbol.end_with?('USDT')
    
    signal_data[:symbol] = symbol.gsub('USDT', '') # Store base symbol
    signal_data[:trading_pair] = symbol # Store full trading pair
    
    # Extract action (BUY/SELL/LONG/SHORT) - handle markdown formatting
    action_match = content.match(/(?:action|side|type).*?(BUY|SELL|LONG|SHORT)/i) ||
                  content.match(/\b(BUY|SELL|LONG|SHORT)\b/i)
    return nil unless action_match
    
    side = action_match[1].upcase
    signal_data[:side] = side
    
    # Set order_side for Binance API
    if side == 'LONG' || side == 'BUY'
      signal_data[:order_side] = 'BUY'
    else
      signal_data[:order_side] = 'SELL'
    end
    
    # Extract entry price - handle markdown formatting
    entry_match = content.match(/(?:entry|price).*?(\d+(?:\.\d+)?)/i)
    signal_data[:entry_price] = entry_match[1].to_f if entry_match
    
    # Extract stop loss - handle markdown formatting
    sl_match = content.match(/(?:stop\s*loss|sl).*?(\d+(?:\.\d+)?)/i)
    signal_data[:stop_loss] = sl_match[1].to_f if sl_match
    
    # Extract take profit - handle markdown formatting
    tp_match = content.match(/(?:take\s*profit|tp).*?(\d+(?:\.\d+)?)/i)
    signal_data[:take_profit] = tp_match[1].to_f if tp_match
    
    # Extract risk percentage - handle markdown formatting
    risk_match = content.match(/(?:risk).*?(\d+(?:\.\d+)?)%?/i)
    signal_data[:risk_percentage] = risk_match[1].to_f if risk_match
    signal_data[:risk_percentage] ||= 2.0 # Default 2% risk
    
    # Extract signal ID - handle markdown formatting
    id_match = content.match(/(?:signal\s*id).*?([A-Z0-9_]+)/i)
    signal_data[:signal_id] = id_match[1] if id_match
    
    # Add timestamp
    signal_data[:received_at] = Time.current.to_s
    
    signal_data
  end
end
