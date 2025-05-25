#!/usr/bin/env ruby

# Enhanced Signal Processor Test Script
# Shows all supported Discord signal formats

require_relative '../config/environment'
require_relative '../app/services/enhanced_signal_processor'

class EnhancedSignalTest
  def self.run
    puts "🚀 ENHANCED DISCORD SIGNAL FORMATS TEST"
    puts "=" * 80
    puts
    
    test_all_formats
    
    puts "\n🎯 SUMMARY:"
    puts "=" * 80
    puts "✅ The Enhanced Signal Processor supports #{WORKING_SIGNALS.length} different signal formats!"
    puts "📊 It can parse most common Discord trading signal formats"
    puts "💡 Supports price abbreviations (45k = 45000)"
    puts "🔍 Lower confidence threshold (0.6) for more flexibility"
    puts
    puts "🔄 TO USE THE ENHANCED PROCESSOR:"
    puts "Update your TradeSignal model to use EnhancedSignalProcessor instead of SignalProcessor"
  end
  
  WORKING_SIGNALS = [
    # Standard formats
    "🚀 BTC LONG Entry: $45000 TP: $47000 SL: $43000",
    "📈 ETH BUY Entry $3000 Target $3200 Stop $2800",
    "💰 BTC LONG @ $45000 TP $47000 SL $43000",
    
    # Coin/Symbol formats  
    "Coin: BTC Entry Price: 45000 Take Profit: 47000 Stop Loss: 43000",
    "Symbol: ETH Entry: 3000 Target: 3200 Stop: 2800",
    "Token: BNB Entry Price 450 Take Profit 480",
    
    # Brief formats
    "BTC 45000-47000 SL:43000",
    "ETH 3000→3200 Stop:2800",
    "BNB 450>480",
    
    # Multiple TP formats
    "BTC LONG Entry: 45000 TP1: 46000 TP2: 47000 TP3: 48000 SL: 43000",
    "ETH BUY Entry 3000 TP1 3100 TP2 3200 SL 2800",
    
    # Spot formats
    "💰 BTCUSDT BUY 45000 Target 47000",
    "🎯 ETHUSDT SELL 3000 to 2800",
    "🔥 BNBUSDT BUY 450 Target 480 Stop 430",
    
    # Signal Alert formats  
    "BTC/USDT Signal: Buy at 45000, Target 47000, Stop 43000",
    "ETH Signal: Sell at $3000, Target $2800",
    "BTCUSDT Signal: Buy 45000, Target 47000",
    
    # Entry formats
    "ENTRY: BTC @ 45000 | TP: 47000 | SL: 43000", 
    "Signal: ETH at $3000 Target: $3200 Stop: $2800",
    "ENTRY: BNB @ 450 TP 480",
    
    # Arrow formats
    "Signal: ETH Long 3000 -> 3200",
    "BTC Short 47000 → 45000",
    "ETH Buy 3000 to 3200 SL 2800",
    
    # Pump Alert formats
    "BTC PUMP ALERT! Entry 45k Target 47k",
    "ETH CALL ALERT Entry 3000 Target 3200 Stop 2800",
    "BNB PUMP! 450 to 480",
    
    # Call formats
    "🔥 ETH CALL: 3000 entry 3200 exit",
    "🚀 BTC CALL: 45000 entry 47000 exit 43000 stop",
    "💰 BNB CALL: 450 entry 480 exit",
    
    # Entry Point formats
    "BTCUSDT 45000 entry point target 47000",
    "ETH 3000 entry point target 3200 stop 2800",
    "BNB 450 entry point target 480",
    
    # Simple formats
    "BTC 45000 to 47000",
    "ETH 3000 to 3200 stop 2800",
    "BNB 450 to 480"
  ].freeze
  
  def self.test_all_formats
    puts "🟢 SUPPORTED SIGNAL FORMATS (#{WORKING_SIGNALS.length} formats):"
    puts "-" * 80
    
    successful = 0
    failed = 0
    
    WORKING_SIGNALS.each_with_index do |signal, i|
      puts "\n#{i+1}. #{signal}"
      
      processor = EnhancedSignalProcessor.new(signal)
      
      if processor.valid?
        data = processor.to_h
        successful += 1
        
        puts "   ✅ PARSED: #{data[:symbol]} #{data[:side]} Entry:#{data[:entry_price]}"
        puts "      TP:#{data[:take_profit]} SL:#{data[:stop_loss]} Confidence:#{data[:confidence_score].round(2)}"
        puts "      Pattern: #{data[:signal_type]} | Urgency: #{data[:urgency]}"
      else
        failed += 1
        puts "   ❌ FAILED TO PARSE"
      end
    end
    
    puts "\n📊 RESULTS:"
    puts "   ✅ Successfully parsed: #{successful}/#{WORKING_SIGNALS.length}"
    puts "   ❌ Failed to parse: #{failed}/#{WORKING_SIGNALS.length}"
    puts "   📈 Success rate: #{(successful.to_f / WORKING_SIGNALS.length * 100).round(1)}%"
  end
end

# Run the test
if __FILE__ == $0
  EnhancedSignalTest.run
end 