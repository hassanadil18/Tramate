# Job to monitor active trades and update their status based on Binance order status
class MonitorTradeJob < ApplicationJob
  queue_as :trades

  # Retry failed jobs with backoff
  retry_on Binance::ServerError, wait: 1.minute, attempts: 5
  retry_on StandardError, wait: 30.seconds, attempts: 3

  def perform(trade_id)
    trade = Trade.find_by(id: trade_id)
    
    unless trade
      Rails.logger.error "MonitorTradeJob: Trade #{trade_id} not found"
      return
    end

    # Skip if trade is already completed or failed
    if trade.status.in?(['completed', 'failed', 'cancelled'])
      Rails.logger.info "MonitorTradeJob: Trade #{trade.id} already in final status: #{trade.status}"
      return
    end

    # Skip if no Binance order ID
    unless trade.binance_order_id
      Rails.logger.warn "MonitorTradeJob: Trade #{trade.id} has no Binance order ID"
      return
    end

    Rails.logger.info "MonitorTradeJob: Monitoring trade #{trade.id} (#{trade.symbol})"

    begin
      # Get user's API credentials
      api_credential = trade.user.api_credentials.binance.active.first
      
      unless api_credential
        Rails.logger.error "MonitorTradeJob: No active Binance credentials for user #{trade.user.id}"
        return
      end

      # Initialize Binance service
      binance_service = BinanceService.new(
        api_credential.api_key, 
        api_credential.api_secret,
        testnet: Rails.application.config.binance_testnet
      )

      # Check main order status
      monitor_main_order(trade, binance_service)
      
      # Check take profit order if exists
      monitor_take_profit_order(trade, binance_service) if trade.take_profit_order_id
      
      # Check stop loss order if exists  
      monitor_stop_loss_order(trade, binance_service) if trade.stop_loss_order_id
      
      # Schedule next monitoring if trade is still active
      schedule_next_monitoring(trade)

    rescue Binance::ClientError => e
      handle_binance_error(trade, e)
    rescue => e
      handle_general_error(trade, e)
    end
  end

  private

  def monitor_main_order(trade, binance_service)
    result = binance_service.get_order_status(
      trade.trading_pair,
      order_id: trade.binance_order_id
    )

    unless result[:success]
      Rails.logger.error "Failed to get order status for trade #{trade.id}: #{result[:error]}"
      return
    end

    order_data = result[:data]
    previous_status = trade.order_status

    # Update trade with latest order information
    trade.update!(
      order_status: order_data['status'],
      executed_quantity: order_data['executedQty'].to_f,
      execution_price: order_data['price'].to_f,
      binance_response: order_data,
      last_checked_at: Time.current
    )

    # Handle status changes
    case order_data['status']
    when 'FILLED'
      handle_order_filled(trade, order_data)
    when 'PARTIALLY_FILLED'
      handle_order_partially_filled(trade, order_data)
    when 'CANCELED', 'REJECTED', 'EXPIRED'
      handle_order_failed(trade, order_data)
    end

    # Log status changes
    if previous_status != order_data['status']
      Rails.logger.info "Trade #{trade.id} status changed from #{previous_status} to #{order_data['status']}"
    end
  end

  def monitor_take_profit_order(trade, binance_service)
    result = binance_service.get_order_status(
      trade.trading_pair,
      order_id: trade.take_profit_order_id
    )

    if result[:success]
      order_data = result[:data]
      
      trade.update!(
        take_profit_status: order_data['status'],
        take_profit_order_data: order_data
      )

      if order_data['status'] == 'FILLED'
        handle_take_profit_filled(trade, order_data)
      end
    end
  end

  def monitor_stop_loss_order(trade, binance_service)
    result = binance_service.get_order_status(
      trade.trading_pair,
      order_id: trade.stop_loss_order_id
    )

    if result[:success]
      order_data = result[:data]
      
      trade.update!(
        stop_loss_status: order_data['status'],
        stop_loss_order_data: order_data
      )

      if order_data['status'] == 'FILLED'
        handle_stop_loss_filled(trade, order_data)
      end
    end
  end

  def handle_order_filled(trade, order_data)
    trade.update!(
      status: 'executed',
      execution_price: order_data['price'].to_f,
      executed_quantity: order_data['executedQty'].to_f,
      executed_at: Time.current,
      notes: "Order filled successfully"
    )

    Rails.logger.info "Trade #{trade.id} order filled: #{order_data['executedQty']} #{trade.symbol} at #{order_data['price']}"
    
    # Send notification email
    trade.user.send_trade_notification(trade, :order_filled)
  end

  def handle_order_partially_filled(trade, order_data)
    executed_qty = order_data['executedQty'].to_f
    
    trade.update!(
      execution_price: order_data['price'].to_f,
      executed_quantity: executed_qty,
      notes: "Order partially filled: #{executed_qty} of #{order_data['origQty']}"
    )

    Rails.logger.info "Trade #{trade.id} partially filled: #{executed_qty}/#{order_data['origQty']}"
  end

  def handle_order_failed(trade, order_data)
    trade.update!(
      status: 'failed',
      error_message: "Order #{order_data['status'].downcase}",
      notes: "Order failed with status: #{order_data['status']}"
    )

    Rails.logger.warn "Trade #{trade.id} order failed: #{order_data['status']}"
    
    # Send notification email
    trade.user.send_trade_notification(trade, :order_failed)
  end

  def handle_take_profit_filled(trade, order_data)
    # Calculate profit
    entry_price = trade.execution_price
    exit_price = order_data['price'].to_f
    quantity = order_data['executedQty'].to_f
    
    profit_loss = if trade.order_side == 'BUY'
                    (exit_price - entry_price) * quantity
                  else
                    (entry_price - exit_price) * quantity
                  end

    trade.update!(
      status: 'completed',
      exit_price: exit_price,
      profit_loss: profit_loss,
      completed_at: Time.current,
      exit_reason: 'take_profit',
      notes: "Take profit executed at #{exit_price}"
    )

    Rails.logger.info "Trade #{trade.id} completed with profit: #{profit_loss} USDT"
    
    # Cancel stop loss order if it exists
    cancel_remaining_orders(trade)
    
    # Send notification email
    trade.user.send_trade_notification(trade, :completed)
  end

  def handle_stop_loss_filled(trade, order_data)
    # Calculate loss
    entry_price = trade.execution_price
    exit_price = order_data['price'].to_f
    quantity = order_data['executedQty'].to_f
    
    profit_loss = if trade.order_side == 'BUY'
                    (exit_price - entry_price) * quantity
                  else
                    (entry_price - exit_price) * quantity
                  end

    trade.update!(
      status: 'completed',
      exit_price: exit_price,
      profit_loss: profit_loss,
      completed_at: Time.current,
      exit_reason: 'stop_loss',
      notes: "Stop loss executed at #{exit_price}"
    )

    Rails.logger.info "Trade #{trade.id} stopped out with loss: #{profit_loss} USDT"
    
    # Cancel take profit order if it exists
    cancel_remaining_orders(trade)
    
    # Send notification email
    trade.user.send_trade_notification(trade, :completed)
  end

  def cancel_remaining_orders(trade)
    # This would cancel any remaining open orders for this trade
    # Implementation depends on your order management strategy
    Rails.logger.info "Cancelling remaining orders for completed trade #{trade.id}"
  end

  def schedule_next_monitoring(trade)
    # Schedule next check based on trade status and activity
    next_check_delay = case trade.status
                      when 'pending'
                        30.seconds  # Check pending orders frequently
                      when 'executed'
                        2.minutes   # Monitor executed trades for exit orders
                      else
                        5.minutes   # Default monitoring interval
                      end

    # Only schedule if trade is still active
    if trade.status.in?(['pending', 'executed'])
      MonitorTradeJob.perform_in(next_check_delay, trade.id)
    end
  end

  def handle_binance_error(trade, error)
    error_code = error.response[:code] if error.response.is_a?(Hash)
    error_message = error.response[:msg] if error.response.is_a?(Hash)
    
    Rails.logger.error "Binance error monitoring trade #{trade.id}: #{error_message}"
    
    # Update trade with error information
    trade.update!(
      error_message: "Monitoring error: #{error_message}",
      last_error_at: Time.current
    )

    # Don't retry for certain error codes
    case error_code
    when -2013 # Order does not exist
      trade.update!(
        status: 'failed',
        error_message: "Order not found on Binance"
      )
      return
    end

    # Re-raise for retry mechanism
    raise error
  end

  def handle_general_error(trade, error)
    Rails.logger.error "Error monitoring trade #{trade.id}: #{error.message}"
    
    trade.update!(
      error_message: "Monitoring error: #{error.message}",
      last_error_at: Time.current
    )

    # Re-raise for retry mechanism
    raise error
  end
end 