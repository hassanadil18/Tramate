class UserMailer < ApplicationMailer
  # Use Rails credentials for default from email with fallback
  default from: -> { 
    begin
      Rails.application.credentials.dig(:email, :default_from) || 
      ENV['DEFAULT_FROM_EMAIL'] || 
      'noreply@tramate.com'
    rescue ActiveSupport::MessageEncryptor::InvalidMessage
      ENV['DEFAULT_FROM_EMAIL'] || 'noreply@tramate.com'
    end
  }

  # Send welcome email after user signs up
  def welcome_email(user)
    @user = user
    @login_url = "http://localhost:3000/auth/login" # You can make this dynamic based on environment
    
    mail(
      to: @user.email,
      subject: '🎉 Welcome to Tramate - Your Trading Journey Begins!'
    )
  end

  # Send notification when user signs in
  def signin_notification(user, request = nil)
    @user = user
    @signin_time = Time.current
    @ip_address = request&.remote_ip || 'Unknown'
    @user_agent = request&.user_agent || 'Unknown'
    @location = get_location_from_ip(@ip_address)
    
    mail(
      to: @user.email,
      subject: '🔐 Tramate Account Access Notification'
    )
  end

  # Send notification when a trade is executed
  def trade_executed(user, trade)
    @user = user
    @trade = trade
    @signal = trade.trade_signal
    
    mail(
      to: @user.email,
      subject: "🚀 Trade Executed: #{@trade.symbol} #{@trade.trade_type}"
    )
  end

  # Send notification when a trade is completed (TP/SL hit)
  def trade_completed(user, trade)
    @user = user
    @trade = trade
    @profit_loss = @trade.profit_loss || 0
    @is_profit = @profit_loss > 0
    
    mail(
      to: @user.email,
      subject: "#{@is_profit ? '💰' : '📉'} Trade Completed: #{@trade.symbol} #{@is_profit ? 'Profit' : 'Loss'}"
    )
  end

  # Send notification when a trade fails
  def trade_failed(user, signal, error_message)
    @user = user
    @signal = signal
    @error_message = error_message
    
    mail(
      to: @user.email,
      subject: "⚠️ Trade Failed: #{@signal&.symbol} - Action Required"
    )
  end

  # Send notification when order is filled
  def order_filled(user, trade)
    @user = user
    @trade = trade
    
    mail(
      to: @user.email,
      subject: "✅ Order Filled: #{@trade.symbol} at #{@trade.execution_price}"
    )
  end

  # Send notification when order fails
  def order_failed(user, trade, status)
    @user = user
    @trade = trade
    @status = status
    
    mail(
      to: @user.email,
      subject: "❌ Order Failed: #{@trade.symbol} - #{@status}"
    )
  end

  # Send daily trading summary
  def daily_summary(user, trades_today)
    @user = user
    @trades = trades_today
    @total_trades = @trades.count
    @successful_trades = @trades.select(&:successful?).count
    @total_profit_loss = @trades.sum { |t| t.profit_loss || 0 }
    
    mail(
      to: @user.email,
      subject: "📊 Daily Trading Summary - #{Date.current.strftime('%B %d, %Y')}"
    )
  end

  private

  def get_location_from_ip(ip_address)
    # Simple location detection - you can enhance this with a service like GeoIP
    return 'Unknown' if ip_address == 'Unknown' || ip_address.start_with?('127.', '192.168.', '10.')
    
    # For now, just return the IP. You can integrate with MaxMind GeoIP or similar service
    "IP: #{ip_address}"
  end
end 