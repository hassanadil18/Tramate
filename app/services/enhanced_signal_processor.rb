# Enhanced Signal Processor for Discord Trading Signals
# Handles a wide variety of signal formats from different trading communities
class EnhancedSignalProcessor
  include ActiveModel::Validations
  
  attr_reader :content, :parsed_data, :signal_type, :confidence_score
  
  # Comprehensive signal patterns for various Discord trading communities
  SIGNAL_PATTERNS = {
    # Standard format: "🚀 BTC LONG Entry: $45000 TP: $47000 SL: $43000"
    standard: /(?:🚀|📈|💰|🔥|⚡|🎯)?\s*(?<symbol>[A-Z]{2,10})(?:\/USDT|USDT)?\s+(?<side>LONG|SHORT|BUY|SELL)\s*(?:Entry|EP|@|:)?\s*:?\s*\$?(?<entry>[\d,\.]+)\s*(?:TP|Target|Take\s*Profit)\s*:?\s*\$?(?<take_profit>[\d,\.]+)(?:\s*(?:SL|Stop\s*Loss)\s*:?\s*\$?(?<stop_loss>[\d,\.]+))?/i,
    
    # Coin format: "Coin: BTC Entry Price: 45000 Take Profit: 47000 Stop Loss: 43000"
    coin_format: /(?:Coin|Symbol|Token)\s*:\s*(?<symbol>[A-Z]{2,10})\s*(?:Entry\s*Price|EP|Entry)\s*:\s*\$?(?<entry>[\d,\.]+)\s*(?:Take\s*Profit|TP|Target)\s*:\s*\$?(?<take_profit>[\d,\.]+)(?:\s*(?:Stop\s*Loss|SL|Stop)\s*:\s*\$?(?<stop_loss>[\d,\.]+))?/i,
    
    # Brief format: "BTC 45000-47000 SL:43000"
    brief: /(?<symbol>[A-Z]{2,10})\s+(?<entry>[\d,\.]+)\s*[-–→>]\s*(?<take_profit>[\d,\.]+)(?:\s*(?:SL|Stop)\s*:?\s*(?<stop_loss>[\d,\.]+))?/i,
    
    # Multiple TP format: "BTC LONG Entry: 45000 TP1: 46000 TP2: 47000 TP3: 48000 SL: 43000"
    multiple_tp: /(?<symbol>[A-Z]{2,10})(?:\/USDT|USDT)?\s+(?<side>LONG|SHORT|BUY|SELL)\s*(?:Entry|EP)?\s*:?\s*\$?(?<entry>[\d,\.]+)\s*(?:TP1?\s*:?\s*\$?(?<tp1>[\d,\.]+))?(?:\s*TP2\s*:?\s*\$?(?<tp2>[\d,\.]+))?(?:\s*TP3\s*:?\s*\$?(?<tp3>[\d,\.]+))?(?:\s*(?:SL|Stop)\s*:?\s*\$?(?<stop_loss>[\d,\.]+))?/i,
    
    # Spot format: "💰 BTCUSDT BUY 45000 Target 47000"
    spot_format: /(?:💰|🎯|🔥)?\s*(?<symbol>[A-Z]{2,10}USDT)\s+(?<side>BUY|SELL)\s+(?<entry>[\d,\.]+)\s*(?:Target|TP|to)\s*(?<take_profit>[\d,\.]+)(?:\s*(?:SL|Stop)\s*(?<stop_loss>[\d,\.]+))?/i,
    
    # Signal Alert format: "BTC/USDT Signal: Buy at 45000, Target 47000, Stop 43000"
    signal_alert: /(?<symbol>[A-Z]{2,10})(?:\/USDT|USDT)?\s+Signal\s*:\s*(?<side>Buy|Sell)\s+(?:at\s+)?\$?(?<entry>[\d,\.]+)(?:\s*,?\s*Target\s+\$?(?<take_profit>[\d,\.]+))?(?:\s*,?\s*Stop\s+\$?(?<stop_loss>[\d,\.]+))?/i,
    
    # Entry format: "ENTRY: BTC @ 45000 | TP: 47000 | SL: 43000"
    entry_format: /(?:ENTRY|Signal)\s*:\s*(?<symbol>[A-Z]{2,10})\s*(?:@|at)\s*\$?(?<entry>[\d,\.]+)\s*\|?\s*(?:TP|Target)\s*:\s*\$?(?<take_profit>[\d,\.]+)(?:\s*\|?\s*(?:SL|Stop)\s*:\s*\$?(?<stop_loss>[\d,\.]+))?/i,
    
    # Arrow format: "Signal: ETH Long 3000 -> 3200"
    arrow_format: /(?:Signal\s*:\s*)?(?<symbol>[A-Z]{2,10})\s+(?<side>Long|Short|Buy|Sell)\s+(?<entry>[\d,\.]+)\s*(?:->|→|to)\s*(?<take_profit>[\d,\.]+)(?:\s*(?:SL|Stop)\s*:?\s*(?<stop_loss>[\d,\.]+))?/i,
    
    # Pump Alert format: "BTC PUMP ALERT! Entry 45k Target 47k"
    pump_alert: /(?<symbol>[A-Z]{2,10})\s+(?:PUMP|CALL)\s+ALERT!?\s*(?:Entry\s+)?(?<entry>[\d,\.]+)k?\s*(?:Target\s+)?(?<take_profit>[\d,\.]+)k?(?:\s*(?:Stop|SL)\s+(?<stop_loss>[\d,\.]+)k?)?/i,
    
    # Call format: "🔥 ETH CALL: 3000 entry 3200 exit"
    call_format: /(?:🔥|🚀|💰)?\s*(?<symbol>[A-Z]{2,10})\s+CALL\s*:\s*(?<entry>[\d,\.]+)\s+entry\s+(?<take_profit>[\d,\.]+)\s+exit(?:\s+(?<stop_loss>[\d,\.]+)\s+stop)?/i,
    
    # Entry Point format: "BTCUSDT 45000 entry point target 47000"
    entry_point: /(?<symbol>[A-Z]{2,10}(?:USDT)?)\s+(?<entry>[\d,\.]+)\s+entry\s+point\s+target\s+(?<take_profit>[\d,\.]+)(?:\s+stop\s+(?<stop_loss>[\d,\.]+))?/i,
    
    # Simple format: "BTC 45000 to 47000"
    simple_format: /(?<symbol>[A-Z]{2,10})\s+(?<entry>[\d,\.]+)\s+to\s+(?<take_profit>[\d,\.]+)(?:\s+stop\s+(?<stop_loss>[\d,\.]+))?/i
  }.freeze
  
  # Valid trading symbols (major cryptocurrencies + popular altcoins)
  VALID_SYMBOLS = %w[
    BTC ETH BNB ADA XRP DOT SOL MATIC AVAX ATOM LINK UNI
    LTC BCH XLM ALGO AAVE SUSHI CRV COMP YFI MKR SNX
    DOGE SHIB PEPE FLOKI BONK WIF GMT APE SAND MANA
    FTM NEAR ICP THETA CHZ ENJ BAT ZRX 1INCH GRT
    CAKE ALPHA TLM SFP TRU CTSI HARD REEF AKRO
  ].freeze
  
  # Price multipliers for common abbreviations
  PRICE_MULTIPLIERS = {
    'k' => 1_000,
    'K' => 1_000,
    'm' => 1_000_000,
    'M' => 1_000_000
  }.freeze
  
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
    @confidence_score >= 0.6  # Lower threshold for more flexibility
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
    
    # Clean the content first
    cleaned_content = clean_content(@content)
    
    # Try each pattern
    SIGNAL_PATTERNS.each do |pattern_name, regex|
      match = cleaned_content.match(regex)
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
  
  def clean_content(content)
    # Remove extra whitespace and normalize
    content = content.gsub(/\s+/, ' ').strip
    
    # Convert common symbols
    content = content.gsub('→', '->').gsub('–', '-')
    
    # Normalize price indicators
    content = content.gsub(/(\d+)k\b/i) { |match| (match.to_f * 1000).to_i.to_s }
    content = content.gsub(/(\d+)m\b/i) { |match| (match.to_f * 1_000_000).to_i.to_s }
    
    content
  end
  
  def extract_data_from_match(match, pattern_type)
    result = {}
    
    # Extract symbol and normalize it
    symbol = match[:symbol]&.upcase&.gsub(/USDT$/, '')
    return nil unless VALID_SYMBOLS.include?(symbol)
    
    result[:symbol] = symbol
    result[:trading_pair] = "#{symbol}USDT"
    
    # Extract side (BUY/SELL or LONG/SHORT) with better handling
    side = extract_side(match, pattern_type)
    result[:side] = side
    result[:order_side] = side == 'LONG' ? 'BUY' : 'SELL'
    
    # Extract prices with enhanced parsing
    entry_price = extract_price(match, :entry)
    return nil unless entry_price
    result[:entry_price] = entry_price
    
    # Handle take profit
    if pattern_type == :multiple_tp
      take_profits = extract_multiple_take_profits(match)
      result[:take_profit_levels] = take_profits if take_profits.any?
      result[:take_profit] = take_profits.first if take_profits.any?
    else
      take_profit = extract_price(match, :take_profit)
      result[:take_profit] = take_profit if take_profit
    end
    
    # Handle stop loss
    stop_loss = extract_price(match, :stop_loss)
    result[:stop_loss] = stop_loss if stop_loss
    
    result
  end
  
  def extract_side(match, pattern_type)
    side = nil
    
    # Try to extract side from match
    begin
      side = match[:side]&.upcase
    rescue IndexError
      # Side group doesn't exist
    end
    
    # Normalize side
    case side
    when 'BUY', 'LONG'
      'LONG'
    when 'SELL', 'SHORT'
      'SHORT'
    else
      # Default based on pattern or content analysis
      if @content.downcase.include?('short') || @content.downcase.include?('sell')
        'SHORT'
      else
        'LONG' # Default to LONG
      end
    end
  end
  
  def extract_price(match, price_key)
    begin
      price_str = match[price_key]
      return nil unless price_str
      
      parse_price(price_str)
    rescue IndexError
      nil
    end
  end
  
  def extract_multiple_take_profits(match)
    take_profits = []
    
    [:tp1, :tp2, :tp3].each do |tp_key|
      begin
        tp_value = match[tp_key]
        price = parse_price(tp_value) if tp_value
        take_profits << price if price
      rescue IndexError
        # This TP group doesn't exist, skip it
      end
    end
    
    take_profits
  end
  
  def parse_price(price_str)
    return nil unless price_str
    
    # Handle price abbreviations (k, m)
    price_str = price_str.to_s.strip
    
    # Check for multipliers
    multiplier = 1
    PRICE_MULTIPLIERS.each do |suffix, mult|
      if price_str.end_with?(suffix)
        multiplier = mult
        price_str = price_str[0...-suffix.length]
        break
      end
    end
    
    # Remove commas, dollar signs, and convert to float
    cleaned = price_str.gsub(/[,$]/, '')
    Float(cleaned) * multiplier
  rescue ArgumentError
    nil
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
    
    # Ensure reasonable price ranges (basic sanity check)
    return false if data[:entry_price] <= 0
    return false if data[:take_profit] && data[:take_profit] <= 0
    return false if data[:stop_loss] && data[:stop_loss] <= 0
    
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
    score = 0.4 # Lower base score for flexibility
    
    # Pattern type scoring (more lenient)
    case pattern_type
    when :standard, :signal_alert, :entry_format
      score += 0.3
    when :coin_format, :call_format
      score += 0.25
    when :multiple_tp, :pump_alert
      score += 0.2
    when :spot_format, :arrow_format
      score += 0.15
    when :brief, :simple_format, :entry_point
      score += 0.1
    end
    
    # Data completeness scoring
    score += 0.15 if data[:take_profit]
    score += 0.1 if data[:stop_loss]
    score += 0.05 if data[:side]
    score += 0.1 if data[:risk_reward_ratio] && data[:risk_reward_ratio] >= 1.5
    
    # Symbol popularity scoring
    top_symbols = %w[BTC ETH BNB ADA XRP SOL]
    score += 0.05 if top_symbols.include?(data[:symbol])
    
    # Content quality indicators
    score += 0.05 if @content.include?('🚀') || @content.include?('💰') || @content.include?('🔥')
    score += 0.05 if @content.upcase.include?('SIGNAL') || @content.upcase.include?('CALL')
    
    [score, 1.0].min
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
    urgent_indicators = ['🚨', 'NOW', 'URGENT', 'FAST', 'QUICK', 'ASAP', 'ALERT', 'PUMP']
    
    if urgent_indicators.any? { |indicator| @content.upcase.include?(indicator) }
      'high'
    elsif @content.include?('🚀') || @content.include?('💰') || @content.include?('🔥')
      'medium'
    else
      'low'
    end
  end
end 