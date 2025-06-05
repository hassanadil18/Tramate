#!/usr/bin/env ruby

# Binance Integration Test Script
# Tests the official Binance API integration using testnet

require_relative '../config/environment'

class BinanceIntegrationTest
  def self.run
    puts "🚀 Testing Binance Integration (#{Rails.application.config.binance_testnet ? 'TESTNET' : 'MAINNET'})"
    puts "=" * 60
    
    # Test 1: Basic connectivity
    test_connectivity
    
    # Test 2: Signal processing
    test_signal_processing
    
    # Test 3: Service initialization (without real API keys)
    test_service_initialization
    
    puts "\n✅ All tests completed!"
  end
  
  private
  
  def self.test_connectivity
    puts "\n📡 Test 1: API Connectivity"
    
    begin
      # Test with dummy credentials to check connectivity
      service = BinanceService.new('dummy_key_' + '0' * 56, 'dummy_secret_' + '0' * 56)
      
      if service.test_connectivity
        puts "✅ Binance API connectivity: OK"
      else
        puts "❌ Binance API connectivity: FAILED"
      end
      
    rescue => e
      puts "❌ Connectivity test failed: #{e.message}"
    end
  end
  
  def self.test_signal_processing
    puts "\n🔍 Test 2: Signal Processing"
    
    test_signals = [
      "🚀 BTC LONG Entry: $45000 TP: $47000 SL: $43000",
      "Coin: ETH Entry Price: 3000 Take Profit: 3200 Stop Loss: 2800",
      "BTC 45000-47000 SL:43000",
      "💰 BTCUSDT BUY 45000 Target 47000",
      "INVALID SIGNAL TEXT"
    ]
    
    test_signals.each_with_index do |signal_text, index|
      puts "\n  Signal #{index + 1}: #{signal_text[0..50]}..."
      
      processor = SignalProcessor.new(signal_text)
      
      if processor.valid?
        data = processor.to_h
        puts "  ✅ Parsed: #{data[:symbol]} #{data[:side]} Entry:#{data[:entry_price]} TP:#{data[:take_profit]} (Confidence: #{data[:confidence_score]})"
      else
        puts "  ❌ Failed to parse signal"
      end
    end
  end
  
  def self.test_service_initialization
    puts "\n⚙️  Test 3: Service Initialization"
    
    begin
      # Test BinanceService initialization
      service = BinanceService.new
      puts "✅ BinanceService initialized successfully"
      
      # Test configuration
      puts "✅ Testnet mode: #{Rails.application.config.binance_testnet}"
      puts "✅ Base URL: #{Rails.application.config.binance_spot_base_url}"
      
    rescue => e
      puts "❌ Service initialization failed: #{e.message}"
    end
  end
end

# Run the tests
if __FILE__ == $0
  BinanceIntegrationTest.run
end 