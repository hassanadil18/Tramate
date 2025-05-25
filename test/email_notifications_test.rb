#!/usr/bin/env ruby

# Email Notifications Test Script
# Tests all email notifications in the Tramate system

require_relative '../config/environment'

class EmailNotificationsTest
  def self.run
    puts "🧪 TRAMATE EMAIL NOTIFICATIONS TEST"
    puts "=" * 60
    puts
    
    # Test email configuration
    test_email_configuration
    
    # Test user signup email
    test_welcome_email
    
    # Test signin notification
    test_signin_notification
    
    # Test trade notifications
    test_trade_notifications
    
    puts "\n✅ EMAIL NOTIFICATIONS TEST COMPLETED!"
    puts "=" * 60
    puts "📧 Check your email inbox for test notifications"
    puts "🔧 If emails aren't arriving, check your SMTP configuration"
  end
  
  private
  
  def self.test_email_configuration
    puts "🔧 Testing Email Configuration..."
    
    # Check if email delivery is enabled
    delivery_enabled = ActionMailer::Base.perform_deliveries
    puts "   📤 Email delivery enabled: #{delivery_enabled ? '✅' : '❌'}"
    
    # Check delivery method
    delivery_method = ActionMailer::Base.delivery_method
    puts "   📮 Delivery method: #{delivery_method}"
    
    # Check SMTP settings
    if delivery_method == :smtp
      smtp_settings = ActionMailer::Base.smtp_settings
      puts "   🌐 SMTP server: #{smtp_settings[:address]}:#{smtp_settings[:port]}"
      puts "   👤 SMTP username: #{smtp_settings[:user_name] ? '✅ Set' : '❌ Missing'}"
      puts "   🔑 SMTP password: #{smtp_settings[:password] ? '✅ Set' : '❌ Missing'}"
    end
    
    puts
  end
  
  def self.test_welcome_email
    puts "📧 Testing Welcome Email..."
    
    begin
      # Create a test user
      test_user = User.new(
        full_name: "Test User",
        email: "test@example.com",
        password: "password123"
      )
      
      # Test the welcome email without saving the user
      UserMailer.welcome_email(test_user).deliver_now
      
      puts "   ✅ Welcome email sent successfully"
    rescue => e
      puts "   ❌ Welcome email failed: #{e.message}"
    end
    
    puts
  end
  
  def self.test_signin_notification
    puts "🔐 Testing Signin Notification..."
    
    begin
      # Find or create a test user
      test_user = User.first || create_test_user
      
      # Create a mock request object
      mock_request = OpenStruct.new(
        remote_ip: '192.168.1.1',
        user_agent: 'Mozilla/5.0 (Test Browser)'
      )
      
      # Test signin notification
      UserMailer.signin_notification(test_user, mock_request).deliver_now
      
      puts "   ✅ Signin notification sent successfully"
    rescue => e
      puts "   ❌ Signin notification failed: #{e.message}"
    end
    
    puts
  end
  
  def self.test_trade_notifications
    puts "📈 Testing Trade Notifications..."
    
    begin
      # Find or create test user and trade signal
      test_user = User.first || create_test_user
      test_signal = create_test_signal
      test_trade = create_test_trade(test_user, test_signal)
      
      # Test trade executed notification
      puts "   🚀 Testing trade executed notification..."
      UserMailer.trade_executed(test_user, test_trade).deliver_now
      puts "   ✅ Trade executed email sent"
      
      # Test trade completed notification (profit)
      puts "   💰 Testing trade completed notification (profit)..."
      test_trade.profit_loss = 150.50
      UserMailer.trade_completed(test_user, test_trade).deliver_now
      puts "   ✅ Trade completed (profit) email sent"
      
      # Test trade completed notification (loss)
      puts "   📉 Testing trade completed notification (loss)..."
      test_trade.profit_loss = -75.25
      UserMailer.trade_completed(test_user, test_trade).deliver_now
      puts "   ✅ Trade completed (loss) email sent"
      
      # Test trade failed notification
      puts "   ⚠️ Testing trade failed notification..."
      UserMailer.trade_failed(test_user, test_signal, "Insufficient balance").deliver_now
      puts "   ✅ Trade failed email sent"
      
    rescue => e
      puts "   ❌ Trade notifications failed: #{e.message}"
    end
    
    puts
  end
  
  def self.create_test_user
    User.create!(
      full_name: "Test User",
      email: "test.user@tramate.com",
      password: "password123",
      admin: false
    )
  end
  
  def self.create_test_signal
    # Create a test channel if it doesn't exist
    channel = Channel.first || Channel.create!(
      name: "Test Channel",
      description: "Test trading channel",
      discord_channel_id: "123456789"
    )
    
    # Create signal with parsed_data instead of individual attributes
    signal = TradeSignal.create!(
      channel: channel,
      message_content: "🚀 BTC LONG Entry: $45000 TP: $47000 SL: $43000",
      parsed_data: {
        symbol: "BTC",
        side: "LONG",
        entry_price: 45000,
        take_profit: 47000,
        stop_loss: 43000,
        confidence_score: 0.85,
        trading_pair: "BTCUSDT"
      },
      confidence_score: 0.85,
      signal_type: "standard",
      status: "processed"
    )
    
    signal
  end
  
  def self.create_test_trade(user, signal)
    trade = Trade.create!(
      user: user,
      trade_signal: signal,
      status: "executed",
      amount: 0.001,
      timestamp: Time.current
    )
    
    # Set additional data using the model methods
    trade.execution_price = 45050
    trade.executed_quantity = 0.001
    trade.binance_order_id = "12345678"
    trade.executed_at = Time.current
    trade.save!
    
    trade
  end
end

# Run the test if this file is executed directly
if __FILE__ == $0
  EmailNotificationsTest.run
end 