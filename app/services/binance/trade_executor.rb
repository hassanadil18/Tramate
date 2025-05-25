# Comprehensive Trading Executor using Official Binance API
# Handles spot trading with proper order management, risk controls, and error handling
class Binance::TradeExecutor
  include Rails.application.routes.url_helpers
  
  attr_reader :user, :api_credential, :binance_service, :trade, :trade_settings
  
  def initialize(user, api_credential)
    @user = user
    @api_credential = api_credential
    @binance_service = BinanceService.new(
      api_credential.api_key, 
      api_credential.api_secret,
      testnet: Rails.application.config.binance_testnet
    )
    @trade_settings = user.trade_settings || default_trade_settings
    
    Rails.logger.info "TradeExecutor initialized for user #{user.id} (#{Rails.application.config.binance_testnet ? 'TESTNET' : 'MAINNET'})"
  end
  
  # Execute a trade based on a signal
  def execute_signal_trade(signal)
    return { success: false, error: "Invalid signal" } unless signal&.tradeable?
    
    # Check if user can execute trade (subscription limits, etc.)
    unless user.can_execute_trade?
      return { success: false, error: "Trade limit exceeded for current subscription" }
    end
    
    # Create trade record
    @trade = user.trades.create!(
      trade_signal: signal,
      symbol: signal.symbol,
      trading_pair: signal.trading_pair,
      entry_price: signal.entry_price,
      target_price: signal.take_profit,
      stop_loss: signal.stop_loss,
      order_side: signal.order_side,
      trade_type: signal.side,
      status: 'pending',
      urgency: signal.urgency,
      confidence_score: signal.confidence_score
    )
    
    begin
      # Execute the main entry order
      entry_result = execute_entry_order(signal)
      
      if entry_result[:success]
        # Update trade with execution details
        update_trade_from_order(entry_result[:order_data])
        
        # Place conditional orders (TP/SL) if available
        place_conditional_orders(signal) if entry_result[:filled]
        
        # Record successful execution
        user.record_trade
        
        Rails.logger.info "Trade executed successfully: #{@trade.id} - #{signal.symbol} #{signal.side}"
        
        {
          success: true,
          trade: @trade,
          order_data: entry_result[:order_data],
          message: "Trade executed successfully"
        }
      else
        # Mark trade as failed
        @trade.update!(
          status: 'failed',
          error_message: entry_result[:error],
          notes: "Failed to execute entry order: #{entry_result[:error]}"
        )
        
        entry_result
      end
      
    rescue => e
      handle_trade_error(e)
    end
  end
  
  # Execute entry order
  def execute_entry_order(signal)
    # Get current market price for validation
    price_result = @binance_service.get_symbol_price(signal.trading_pair)
    
    unless price_result[:success]
      return { success: false, error: "Failed to get current price: #{price_result[:error]}" }
    end
    
    current_price = price_result[:price]
    entry_price = signal.entry_price
    
    # Determine order type and parameters
    order_params = build_entry_order_params(signal, current_price)
    
    # Validate order parameters
    validation_result = validate_order_params(order_params, current_price)
    return validation_result unless validation_result[:success]
    
    # Execute the order
    Rails.logger.info "Executing entry order: #{order_params}"
    order_result = @binance_service.create_order(order_params)
    
    if order_result[:success]
      order_data = order_result[:data]
      
      # Update trade with order information
      @trade.update!(
        binance_order_id: order_data['orderId'],
        execution_price: order_data['price']&.to_f || current_price,
        executed_quantity: order_data['executedQty']&.to_f,
        order_status: order_data['status'],
        binance_response: order_data
      )
      
      {
        success: true,
        order_data: order_data,
        filled: order_data['status'] == 'FILLED',
        current_price: current_price
      }
    else
      {
        success: false,
        error: order_result[:message] || "Order execution failed"
      }
    end
  end
  
  # Place take profit and stop loss orders
  def place_conditional_orders(signal)
    return unless @trade&.executed_quantity&.positive?
    
    # Place take profit order
    if signal.take_profit
      place_take_profit_order(signal)
    end
    
    # Place stop loss order
    if signal.stop_loss
      place_stop_loss_order(signal)
    end
  end
  
  # Place take profit order
  def place_take_profit_order(signal)
    tp_params = {
      symbol: signal.trading_pair,
      side: signal.order_side == 'BUY' ? 'SELL' : 'BUY',
      type: 'LIMIT',
      quantity: @trade.executed_quantity,
      price: signal.take_profit,
      time_in_force: 'GTC',
      client_order_id: "TP_#{@trade.id}_#{Time.current.to_i}"
    }
    
    tp_result = @binance_service.create_order(tp_params)
    
    if tp_result[:success]
      @trade.update!(
        take_profit_order_id: tp_result[:order_id],
        take_profit_order_data: tp_result[:data]
      )
      Rails.logger.info "Take profit order placed: #{tp_result[:order_id]}"
    else
      Rails.logger.error "Failed to place take profit order: #{tp_result[:message]}"
    end
  end
  
  # Place stop loss order
  def place_stop_loss_order(signal)
    # Use OCO order for better execution
    oco_params = {
      symbol: signal.trading_pair,
      side: signal.order_side == 'BUY' ? 'SELL' : 'BUY',
      quantity: @trade.executed_quantity,
      price: (signal.stop_loss * 0.995).round(8), # Limit price slightly below stop price
      stop_price: signal.stop_loss,
      stop_limit_price: (signal.stop_loss * 0.99).round(8), # Execute below stop for certainty
      client_order_id: "SL_#{@trade.id}_#{Time.current.to_i}"
    }
    
    # For now, use a simple STOP_LOSS_LIMIT order
    sl_params = {
      symbol: signal.trading_pair,
      side: signal.order_side == 'BUY' ? 'SELL' : 'BUY',
      type: 'STOP_LOSS_LIMIT',
      quantity: @trade.executed_quantity,
      price: (signal.stop_loss * 0.995).round(8),
      stop_price: signal.stop_loss,
      time_in_force: 'GTC',
      client_order_id: "SL_#{@trade.id}_#{Time.current.to_i}"
    }
    
    sl_result = @binance_service.create_order(sl_params)
    
    if sl_result[:success]
      @trade.update!(
        stop_loss_order_id: sl_result[:order_id],
        stop_loss_order_data: sl_result[:data]
      )
      Rails.logger.info "Stop loss order placed: #{sl_result[:order_id]}"
    else
      Rails.logger.error "Failed to place stop loss order: #{sl_result[:message]}"
    end
  end
  
  # Monitor and update trade status
  def monitor_trade(trade_id)
    trade = Trade.find_by(id: trade_id)
    return unless trade&.binance_order_id
    
    # Check main order status
    status_result = @binance_service.get_order_status(
      trade.trading_pair, 
      order_id: trade.binance_order_id
    )
    
    if status_result[:success]
      order_data = status_result[:data]
      
      # Update trade status based on order status
      case order_data['status']
      when 'FILLED'
        trade.update!(
          status: 'executed',
          execution_price: order_data['price'].to_f,
          executed_quantity: order_data['executedQty'].to_f,
          order_status: 'FILLED'
        )
      when 'PARTIALLY_FILLED'
        trade.update!(
          execution_price: order_data['price'].to_f,
          executed_quantity: order_data['executedQty'].to_f,
          order_status: 'PARTIALLY_FILLED'
        )
      when 'CANCELED', 'REJECTED', 'EXPIRED'
        trade.update!(
          status: 'failed',
          order_status: order_data['status'],
          error_message: "Order #{order_data['status'].downcase}"
        )
      end
    end
  end
  
  private
  
  def build_entry_order_params(signal, current_price)
    # Calculate position size based on user settings and balance
    position_size = calculate_position_size(signal, current_price)
    
    # Determine order type based on signal urgency and price proximity
    order_type = determine_order_type(signal, current_price)
    
    params = {
      symbol: signal.trading_pair,
      side: signal.order_side,
      type: order_type,
      client_order_id: "ENTRY_#{@trade.id}_#{Time.current.to_i}"
    }
    
    case order_type
    when 'MARKET'
      # Use quote order quantity for market orders (spend specific USDT amount)
      params[:quote_order_qty] = position_size
    when 'LIMIT'
      # Use quantity and price for limit orders
      params[:quantity] = (position_size / signal.entry_price).round(8)
      params[:price] = signal.entry_price
      params[:time_in_force] = 'GTC'
    when 'LIMIT_MAKER'
      # Post-only order
      params[:quantity] = (position_size / signal.entry_price).round(8)
      params[:price] = signal.entry_price
    end
    
    params
  end
  
  def calculate_position_size(signal, current_price)
    # Get user's account balance
    account_result = @binance_service.get_account_info
    
    unless account_result[:success]
      # Fallback to default minimum
      return @trade_settings[:min_trade_amount] || 10.0
    end
    
    # Find USDT balance
    usdt_balance = account_result[:data]['balances']
                     .find { |b| b['asset'] == 'USDT' }
                     &.dig('free')&.to_f || 0
    
    # Calculate position size based on user settings
    if @trade_settings[:position_sizing_method] == 'fixed_amount'
      amount = [@trade_settings[:fixed_amount] || 50.0, usdt_balance].min
    elsif @trade_settings[:position_sizing_method] == 'percentage'
      percentage = @trade_settings[:account_percentage] || 5.0
      amount = (usdt_balance * percentage / 100).round(2)
    else
      # Default: fixed amount
      amount = [@trade_settings[:default_amount] || 50.0, usdt_balance].min
    end
    
    # Apply risk management limits
    max_trade_amount = @trade_settings[:max_trade_amount] || (usdt_balance * 0.1)
    min_trade_amount = @trade_settings[:min_trade_amount] || 10.0
    
    amount = [[amount, max_trade_amount].min, min_trade_amount].max
    
    # Ensure we have enough balance
    if amount > usdt_balance
      raise "Insufficient balance: #{usdt_balance} USDT available, #{amount} USDT required"
    end
    
    amount.round(2)
  end
  
  def determine_order_type(signal, current_price)
    price_diff_percent = ((current_price - signal.entry_price).abs / signal.entry_price * 100)
    
    # Use market order if:
    # 1. Signal is urgent
    # 2. Current price is very close to entry price (within 0.5%)
    # 3. User prefers market orders
    if signal.urgent? || 
       price_diff_percent <= 0.5 || 
       @trade_settings[:prefer_market_orders]
      'MARKET'
    elsif @trade_settings[:use_post_only_orders]
      'LIMIT_MAKER'
    else
      'LIMIT'
    end
  end
  
  def validate_order_params(params, current_price)
    # Validate symbol exists and is tradeable
    symbol_info = @binance_service.get_exchange_info(params[:symbol])
    
    unless symbol_info[:success]
      return { success: false, error: "Symbol validation failed: #{symbol_info[:error]}" }
    end
    
    symbol_data = symbol_info[:data]['symbols']&.first
    
    unless symbol_data && symbol_data['status'] == 'TRADING'
      return { success: false, error: "Symbol #{params[:symbol]} is not available for trading" }
    end
    
    # Validate order size meets minimum requirements
    min_qty = symbol_data['filters']
                .find { |f| f['filterType'] == 'LOT_SIZE' }
                &.dig('minQty')&.to_f
    
    if params[:quantity] && min_qty && params[:quantity] < min_qty
      return { success: false, error: "Order quantity below minimum: #{min_qty}" }
    end
    
    # Validate minimum notional value
    min_notional = symbol_data['filters']
                     .find { |f| f['filterType'] == 'MIN_NOTIONAL' }
                     &.dig('minNotional')&.to_f
    
    order_value = if params[:quote_order_qty]
                    params[:quote_order_qty]
                  else
                    (params[:quantity] || 0) * (params[:price] || current_price)
                  end
    
    if min_notional && order_value < min_notional
      return { success: false, error: "Order value below minimum notional: #{min_notional} USDT" }
    end
    
    { success: true }
  end
  
  def update_trade_from_order(order_data)
    @trade.update!(
      binance_order_id: order_data['orderId'],
      execution_price: order_data['price']&.to_f,
      executed_quantity: order_data['executedQty']&.to_f,
      order_status: order_data['status'],
      binance_response: order_data,
      notes: "Order placed successfully at #{Time.current}"
    )
    
    # If order was immediately filled, update status
    if order_data['status'] == 'FILLED'
      @trade.update!(status: 'executed')
    end
  end
  
  def handle_trade_error(error)
    error_message = "Trade execution failed: #{error.message}"
    
    @trade&.update!(
      status: 'failed',
      error_message: error_message,
      error_data: {
        error_class: error.class.name,
        error_message: error.message,
        backtrace: error.backtrace&.first(5),
        timestamp: Time.current
      }
    )
    
    Rails.logger.error error_message
    Rails.logger.error error.backtrace.join("\n") if error.backtrace
    
    {
      success: false,
      error: error_message,
      trade: @trade
    }
  end
  
  def default_trade_settings
    {
      position_sizing_method: 'fixed_amount',
      fixed_amount: 50.0,
      account_percentage: 5.0,
      max_trade_amount: 500.0,
      min_trade_amount: 10.0,
      prefer_market_orders: false,
      use_post_only_orders: false,
      risk_management_enabled: true
    }
  end
end
