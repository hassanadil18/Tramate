# Advanced Signal Processor for Discord Trading Signals
# Handles multiple signal formats and extracts trading parameters
class SignalProcessor
  include ActiveModel::Validations
  
  attr_reader :content, :parsed_data, :signal_type, :confidence_score
  
  # Common signal patterns
  SIGNAL_PATTERNS = {
    # Standard format: "🚀 BTC LONG Entry: $45000 TP: $47000 SL: $43000"
    standard: /(?:🚀|📈|💰)?\s*(?<symbol>[A-Z]{2,10})(?:\/USDT|USDT)?\s+(?<side>LONG|SHORT|BUY|SELL)\s*(?:Entry|EP|@)?\s*:?\s*\$?(?<entry>[\d,\.]+)\s*(?:TP|Target|Take\s*Profit)\s*:?\s*\$?(?<take_profit>[\d,\.]+)(?:\s*(?:SL|Stop\s*Loss)\s*:?\s*\$?(?<stop_loss>[\d,\.]+))?/i,
    
    # Coin format: "Coin: BTC Entry Price: 45000 Take Profit: 47000 Stop Loss: 43000"
    coin_format: /Coin\s*:\s*(?<symbol>[A-Z]{2,10})\s*(?:Entry\s*Price|EP)\s*:\s*\$?(?<entry>[\d,\.]+)\s*(?:Take\s*Profit|TP)\s*:\s*\$?(?<take_profit>[\d,\.]+)(?:\s*(?:Stop\s*Loss|SL)\s*:\s*\$?(?<stop_loss>[\d,\.]+))?/i,
    
    # Brief format: "BTC 45000-47000 SL:43000"
    brief: /(?<symbol>[A-Z]{2,10})\s+(?<entry>[\d,\.]+)\s*[-–]\s*(?<take_profit>[\d,\.]+)(?:\s*SL\s*:?\s*(?<stop_loss>[\d,\.]+))?/i,
    
    # Multiple TP format: "BTC LONG Entry: 45000 TP1: 46000 TP2: 47000 TP3: 48000 SL: 43000"
    multiple_tp: /(?<symbol>[A-Z]{2,10})(?:\/USDT)?\s+(?<side>LONG|SHORT|BUY|SELL)\s*(?:Entry|EP)?\s*:?\s*\$?(?<entry>[\d,\.]+)\s*(?:TP1?\s*:?\s*\$?(?<tp1>[\d,\.]+))?(?:\s*TP2\s*:?\s*\$?(?<tp2>[\d,\.]+))?(?:\s*TP3\s*:?\s*\$?(?<tp3>[\d,\.]+))?(?:\s*(?:SL|Stop)\s*:?\s*\$?(?<stop_loss>[\d,\.]+))?/i,
    
    # Spot format: "💰 BTCUSDT BUY 45000 Target 47000"
    spot_format: /(?:💰|🎯)?\s*(?<symbol>[A-Z]{2,10}USDT)\s+(?<side>BUY|SELL)\s+(?<entry>[\d,\.]+)\s*(?:Target|TP)\s*(?<take_profit>[\d,\.]+)(?:\s*(?:SL|Stop)\s*(?<stop_loss>[\d,\.]+))?/i
  }.freeze
  
  # Valid trading symbols (major cryptocurrencies)
  VALID_SYMBOLS = %w[
    BTC ETH BNB ADA XRP DOT SOL MATIC AVAX ATOM LINK UNI
    LTC BCH XLM ALGO AAVE SUSHI CRV COMP YFI MKR SNX
    DOGE SHIB PEPE FLOKI BONK WIF GMT APE SAND MANA
  ].freeze
  
  def initialize(content)
    @content = content&.strip
    @parsed_data = {}
    @signal_type = nil
    @confidence_score = 0
    
    process_signal if @content.present?
  end
  
  def valid?
    @parsed_data.present? && 
    @parsed_data[:symbol].present? && 
    @parsed_data[:entry_price].present? &&
    @confidence_score >= 0.7
  end
  
  def to_h
    @parsed_data.merge(
      signal_type: @signal_type,
      confidence_score: @confidence_score,
      original_content: @content
    )
  end
  
  private
  
  def process_signal
    return unless @content
    
    # Try each pattern
    SIGNAL_PATTERNS.each do |pattern_name, regex|
      match = @content.match(regex)
      next unless match
      
      result = extract_data_from_match(match, pattern_name)
      next unless result
      
      if validate_extracted_data(result)
        @parsed_data = result
        @signal_type = pattern_name
        @confidence_score = calculate_confidence_score(result, pattern_name)
        break
      end
    end
    
    # Post-process if we found a signal
    if @parsed_data.present?
      normalize_data
      add_metadata
    end
  end
  
  def extract_data_from_match(match, pattern_type)
    result = {}
    
    # Extract symbol and normalize it
    symbol = match[:symbol]&.upcase&.gsub(/USDT$/, '')
    return nil unless VALID_SYMBOLS.include?(symbol)
    
    result[:symbol] = symbol
    result[:trading_pair] = "#{symbol}USDT"
    
    # Extract side (BUY/SELL or LONG/SHORT) - handle missing side group
    side = nil
    begin
      side = match[:side]&.upcase
    rescue IndexError
      # Side group doesn't exist in this pattern, that's okay
    end
    
    if side
      result[:side] = normalize_side(side)
      result[:order_side] = result[:side] == 'LONG' ? 'BUY' : 'SELL'
    else
      # Default to BUY if no side specified
      result[:side] = 'LONG'
      result[:order_side] = 'BUY'
    end
    
    # Extract prices - handle missing groups safely
    begin
      result[:entry_price] = parse_price(match[:entry])
    rescue IndexError
      # Entry group doesn't exist
      result[:entry_price] = nil
    end
    
    return nil unless result[:entry_price]
    
    # Handle take profit (single or multiple)
    if pattern_type == :multiple_tp
      take_profits = []
      
      [:tp1, :tp2, :tp3].each do |tp_key|
        begin
          tp_value = match[tp_key]
          take_profits << parse_price(tp_value) if tp_value
        rescue IndexError
          # This TP group doesn't exist, skip it
        end
      end
      
      if take_profits.any?
        result[:take_profit_levels] = take_profits.compact
        result[:take_profit] = take_profits.first # Primary TP
      end
    else
      begin
        tp_value = match[:take_profit]
        result[:take_profit] = parse_price(tp_value) if tp_value
      rescue IndexError
        # Take profit group doesn't exist
      end
    end
    
    # Handle stop loss safely
    begin
      sl_value = match[:stop_loss]
      result[:stop_loss] = parse_price(sl_value) if sl_value
    rescue IndexError
      # Stop loss group doesn't exist
    end
    
    result
  end
  
  def validate_extracted_data(data)
    return false unless data[:symbol] && data[:entry_price]
    
    # Validate price relationships for LONG positions
    if data[:side] == 'LONG'
      # Take profit should be higher than entry for LONG
      if data[:take_profit] && data[:take_profit] <= data[:entry_price]
        return false
      end
      
      # Stop loss should be lower than entry for LONG
      if data[:stop_loss] && data[:stop_loss] >= data[:entry_price]
        return false
      end
    elsif data[:side] == 'SHORT'
      # Take profit should be lower than entry for SHORT
      if data[:take_profit] && data[:take_profit] >= data[:entry_price]
        return false
      end
      
      # Stop loss should be higher than entry for SHORT
      if data[:stop_loss] && data[:stop_loss] <= data[:entry_price]
        return false
      end
    end
    
    true
  end
  
  def normalize_data
    # Calculate risk/reward ratio
    if @parsed_data[:take_profit] && @parsed_data[:stop_loss]
      entry = @parsed_data[:entry_price]
      tp = @parsed_data[:take_profit]
      sl = @parsed_data[:stop_loss]
      
      if @parsed_data[:side] == 'LONG'
        risk = entry - sl
        reward = tp - entry
      else
        risk = sl - entry
        reward = entry - tp
      end
      
      @parsed_data[:risk_reward_ratio] = risk > 0 ? (reward / risk).round(2) : 0
    end
    
    # Add percentage targets
    if @parsed_data[:take_profit]
      entry = @parsed_data[:entry_price]
      tp = @parsed_data[:take_profit]
      
      if @parsed_data[:side] == 'LONG'
        @parsed_data[:take_profit_percent] = ((tp - entry) / entry * 100).round(2)
      else
        @parsed_data[:take_profit_percent] = ((entry - tp) / entry * 100).round(2)
      end
    end
    
    if @parsed_data[:stop_loss]
      entry = @parsed_data[:entry_price]
      sl = @parsed_data[:stop_loss]
      
      if @parsed_data[:side] == 'LONG'
        @parsed_data[:stop_loss_percent] = ((entry - sl) / entry * 100).round(2)
      else
        @parsed_data[:stop_loss_percent] = ((sl - entry) / entry * 100).round(2)
      end
    end
  end
  
  def add_metadata
    @parsed_data[:processed_at] = Time.current
    @parsed_data[:binance_symbol] = "#{@parsed_data[:symbol]}USDT"
    @parsed_data[:is_valid] = true
    
    # Add recommended order type
    @parsed_data[:recommended_order_type] = determine_order_type
    
    # Add urgency level based on content indicators
    @parsed_data[:urgency] = determine_urgency
  end
  
  def calculate_confidence_score(data, pattern_type)
    score = 0.5 # Base score
    
    # Pattern type scoring
    case pattern_type
    when :standard
      score += 0.3
    when :coin_format
      score += 0.2
    when :multiple_tp
      score += 0.25
    when :spot_format
      score += 0.2
    when :brief
      score += 0.1
    end
    
    # Data completeness scoring
    score += 0.1 if data[:take_profit]
    score += 0.1 if data[:stop_loss]
    score += 0.05 if data[:side]
    score += 0.05 if data[:risk_reward_ratio] && data[:risk_reward_ratio] >= 1.5
    
    # Symbol popularity scoring
    top_symbols = %w[BTC ETH BNB ADA XRP]
    score += 0.05 if top_symbols.include?(data[:symbol])
    
    [score, 1.0].min
  end
  
  def parse_price(price_str)
    return nil unless price_str
    
    # Remove commas and convert to float
    cleaned = price_str.gsub(/[,$]/, '')
    Float(cleaned)
  rescue ArgumentError
    nil
  end
  
  def normalize_side(side)
    case side.upcase
    when 'BUY', 'LONG'
      'LONG'
    when 'SELL', 'SHORT'
      'SHORT'
    else
      'LONG' # Default
    end
  end
  
  def determine_order_type
    # If we have exact entry price, use LIMIT order
    # If urgent signal, use MARKET order
    if @parsed_data[:urgency] == 'high'
      'MARKET'
    else
      'LIMIT'
    end
  end
  
  def determine_urgency
    urgent_indicators = ['🚨', 'NOW', 'URGENT', 'FAST', 'QUICK', 'ASAP']
    
    if urgent_indicators.any? { |indicator| @content.upcase.include?(indicator) }
      'high'
    elsif @content.include?('🚀') || @content.include?('💰')
      'medium'
    else
      'low'
    end
  end
end 