class ExecuteTradeJob < ApplicationJob
  queue_as :trades

  # Retry failed jobs with exponential backoff
  retry_on Binance::ClientError, wait: :exponentially_longer, attempts: 3
  retry_on Binance::ServerError, wait: 30.seconds, attempts: 5
  retry_on StandardError, wait: 10.seconds, attempts: 2

  def perform(signal_id)
    signal = TradeSignal.find_by(id: signal_id)
    
    unless signal&.tradeable?
      Rails.logger.warn "ExecuteTradeJob: Signal #{signal_id} is not tradeable"
      return
    end

    Rails.logger.info "ExecuteTradeJob: Processing signal #{signal.id} - #{signal.symbol} #{signal.side}"

    # Get all users who have access to this signal's channel
    channel = signal.channel
    eligible_users = channel.users.joins(:api_credentials)
                           .where(api_credentials: { platform: 'binance', active: true })
                           .where('subscription_status = ? OR subscription_status IS NULL', 'active')

    Rails.logger.info "ExecuteTradeJob: Found #{eligible_users.count} eligible users for signal #{signal.id}"

    # Process each user's trade
    eligible_users.find_each do |user|
      process_user_trade(user, signal)
    end

    # Update signal status
    signal.update!(
      status: 'processed',
      processed_at: Time.current,
      trades_created: signal.trades.count
    )

    Rails.logger.info "ExecuteTradeJob: Completed processing signal #{signal.id}"
  end

  private

  def process_user_trade(user, signal)
    # Check if user can execute trades (subscription limits, balance, etc.)
    unless user.can_execute_trade?
      Rails.logger.info "User #{user.id} cannot execute trade: subscription limits exceeded"
      return
    end

    # Get user's active Binance credentials
    api_credential = user.api_credentials.binance.active.first
    
    unless api_credential
      Rails.logger.warn "User #{user.id} has no active Binance API credentials"
      return
    end

    begin
      # Initialize trade executor
      executor = Binance::TradeExecutor.new(user, api_credential)
      
      # Execute the trade
      result = executor.execute_signal_trade(signal)
      
      if result[:success]
        Rails.logger.info "Trade executed successfully for user #{user.id}: #{result[:trade].id}"
        
        # Schedule monitoring job for the trade
        MonitorTradeJob.perform_in(30.seconds, result[:trade].id)
        
        # Send success notification email
        user.send_trade_notification(result[:trade], :executed)
        
      else
        Rails.logger.error "Trade execution failed for user #{user.id}: #{result[:error]}"
        
        # Create failed trade record for tracking
        create_failed_trade_record(user, signal, result[:error])
        
        # Send failure notification email
        user.send_trade_notification(nil, :failed) # Will use signal from failed trade record
      end

    rescue Binance::ClientError => e
      handle_binance_client_error(user, signal, e)
    rescue Binance::ServerError => e
      handle_binance_server_error(user, signal, e)
    rescue => e
      handle_general_error(user, signal, e)
    end
  end

  def create_failed_trade_record(user, signal, error_message)
    user.trades.create!(
      trade_signal: signal,
      symbol: signal.symbol,
      trading_pair: signal.trading_pair,
      entry_price: signal.entry_price,
      target_price: signal.take_profit,
      stop_loss: signal.stop_loss,
      order_side: signal.order_side,
      trade_type: signal.side,
      status: 'failed',
      error_message: error_message,
      notes: "Failed during job execution: #{error_message}",
      created_at: Time.current
    )
  rescue => e
    Rails.logger.error "Failed to create failed trade record: #{e.message}"
  end

  def handle_binance_client_error(user, signal, error)
    error_code = error.response[:code] if error.response.is_a?(Hash)
    error_message = error.response[:msg] if error.response.is_a?(Hash)
    
    case error_code
    when -2010 # Insufficient balance
      Rails.logger.warn "User #{user.id} has insufficient balance for trade"
      create_failed_trade_record(user, signal, "Insufficient balance")
      
    when -1013 # Invalid quantity
      Rails.logger.warn "Invalid quantity for user #{user.id} trade"
      create_failed_trade_record(user, signal, "Invalid order quantity")
      
    when -1111 # Invalid symbol
      Rails.logger.error "Invalid symbol #{signal.symbol} for user #{user.id}"
      create_failed_trade_record(user, signal, "Invalid trading symbol")
      
    else
      Rails.logger.error "Binance API error for user #{user.id}: #{error_message}"
      create_failed_trade_record(user, signal, error_message || "Binance API error")
    end
  end

  def handle_binance_server_error(user, signal, error)
    Rails.logger.error "Binance server error for user #{user.id}: #{error.message}"
    
    # Don't create failed trade record for server errors - these should be retried
    # The retry mechanism will handle this
    raise error
  end

  def handle_general_error(user, signal, error)
    Rails.logger.error "Unexpected error processing trade for user #{user.id}: #{error.message}"
    Rails.logger.error error.backtrace.join("\n")
    
    create_failed_trade_record(user, signal, "System error: #{error.message}")
    
    # Re-raise for retry mechanism, but with more context
    raise StandardError, "Trade processing failed for user #{user.id}: #{error.message}"
  end
end
