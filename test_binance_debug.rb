#!/usr/bin/env ruby

# Quick Binance API test script for binance-connector-ruby gem
require_relative 'config/environment'

puts "🔍 BINANCE API DEBUG TEST (binance-connector-ruby)"
puts "=" * 60

begin
  puts "\n1. Testing gem loading..."
  require 'binance'
  puts "✅ Binance gem loaded successfully"
  
  puts "\n2. Testing client initialization (public only)..."
  public_client = Binance::Spot.new
  puts "✅ Public Binance client created successfully"
  
  puts "\n3. Testing public endpoint (server time)..."
  result = public_client.time
  puts "✅ Server time retrieved: #{Time.at(result['serverTime'] / 1000.0)}"
  
  puts "\n4. Testing client with dummy credentials..."
  test_key = 'vmPUZE6mv9SD5VNHk4HlWFsOr6aKE2zvsw0MuIgwCIPy6utIco14y7Ju91duEh8A'
  test_secret = 'NhqPtmdSJYdKjVHjA7PZj4Mge3R5YNiP1e3UZjInClVN65XAbvqqM6A7H5fATj0j'
  
  auth_client = Binance::Spot.new(key: test_key, secret: test_secret)
  puts "✅ Authenticated Binance client created successfully"
  
  puts "\n5. Testing BinanceService class initialization..."
  service = BinanceService.new(test_key, test_secret)
  puts "✅ BinanceService initialized"
  puts "Client present: #{service.client.present?}"
  
  puts "\n6. Testing connectivity..."
  connectivity = service.test_connectivity
  puts "Connectivity test: #{connectivity ? '✅ PASS' : '❌ FAIL'}"
  
  puts "\n7. Testing API validation (will fail with dummy keys)..."
  validation = service.validate_api_keys
  puts "Validation result: #{validation[:success] ? '✅ PASS' : '❌ FAIL'}"
  puts "Message: #{validation[:message]}"
  
  if !validation[:success]
    puts "\n8. Testing error handling..."
    puts "This is expected - dummy credentials should fail validation"
    puts "Error contains API key validation info: #{validation[:message].include?('API') ? '✅ PASS' : '❌ FAIL'}"
  end
  
rescue => e
  puts "❌ Error: #{e.message}"
  puts "Error class: #{e.class}"
  puts "Backtrace:"
  puts e.backtrace.first(8).join("\n")
end

puts "\n" + "=" * 60
puts "Debug test completed!"
puts "Next step: Try with real Binance API credentials" 