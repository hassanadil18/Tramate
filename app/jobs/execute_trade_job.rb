class ExecuteTradeJob < ApplicationJob
  queue_as :trades

  # Retry failed jobs
  retry_on StandardError, wait: 5.seconds, attempts: 3

  def perform(trade_id, credential_id)
    trade = Trade.find_by(id: trade_id)
    api_credential = ApiCredential.find_by(id: credential_id)

    return unless trade && api_credential && api_credential.active?

    begin
      # Initialize Binance client with user's credentials
      client = Binance::ApiClient.new(
        api_key: api_credential.api_key,
        api_secret: api_credential.api_secret
      )

      # Format the trading pair (e.g., "BTCUSDT")
      symbol = "#{trade.coin}USDT"

      # Get current price to determine if we should enter
      current_price = client.price(symbol: symbol).to_f

      # Log the current state
      Rails.logger.info "Trade #{trade.id}: Checking #{symbol} at #{current_price}, target entry: #{trade.entry_price}"

      # Verify if the current price is close to the suggested entry price (within 1%)
      price_diff_percentage = ((current_price - trade.entry_price.to_f).abs / trade.entry_price.to_f) * 100

      if price_diff_percentage > 1.0
        # Price has moved too far from the entry point
        trade.update(
          status: "skipped",
          notes: "Current price (#{current_price}) differs from entry price (#{trade.entry_price}) by #{price_diff_percentage.round(2)}%"
        )
        return
      end

      # Fetch user's account information to check balance
      account_info = client.account_info

      # Determine trade amount - either use configured amount per trade or percentage
      user_trade_settings = trade.user.trade_settings || {}
      trade_amount_settings = user_trade_settings[:amount_per_trade] || 50.0  # Default $50 per trade

      # Check if user has sufficient USDT balance
      usdt_balance = account_info["balances"].find { |b| b["asset"] == "USDT" }
      usdt_available = usdt_balance ? usdt_balance["free"].to_f : 0

      # Set the trade amount
      usdt_amount = [ trade_amount_settings, usdt_available ].min

      # If balance is too low, skip the trade
      if usdt_amount < 10.0 || usdt_amount < (trade_amount_settings * 0.5)
        trade.update(
          status: "skipped",
          notes: "Insufficient balance: #{usdt_available} USDT available, minimum required: 10.0 USDT"
        )

        # Send notification to user about insufficient funds
        TradeNotifier.insufficient_funds(trade).deliver_later if defined?(TradeNotifier)
        return
      end

      # Calculate the trade quantity based on available funds
      quantity = (usdt_amount / current_price).round(6)

      # Record pre-trade stats for auditing
      pre_trade_data = {
        usdt_balance: usdt_available,
        price: current_price,
        time: Time.now,
        planned_quantity: quantity
      }

      # Execute the market order
      order = client.create_order(
        symbol: symbol,
        side: "BUY",
        type: "MARKET",
        quantity: quantity
      )

      # Fetch order details to confirm execution price and quantity
      order_details = client.order_status(symbol: symbol, order_id: order["orderId"])
      executed_quantity = order_details["executedQty"].to_f
      executed_price = order_details["price"].to_f

      # Record the order information
      trade.update(
        status: "executed",
        execution_price: executed_price || current_price,
        quantity: executed_quantity || quantity,
        order_id: order["orderId"],
        notes: "Order executed at #{Time.now}",
        pre_trade_data: pre_trade_data,
        post_trade_data: {
          executed_price: executed_price,
          executed_quantity: executed_quantity,
          order_details: order_details,
          time: Time.now
        }
      )

      # Place take profit order
      if trade.target_price.present?
        tp_order = client.create_order(
          symbol: symbol,
          side: "SELL",
          type: "LIMIT",
          quantity: executed_quantity || quantity,
          price: trade.target_price,
          time_in_force: "GTC"
        )

        trade.update(
          take_profit_order_id: tp_order["orderId"],
          take_profit_data: tp_order
        )
      end

      # Place stop loss order
      if trade.stop_loss.present?
        sl_order = client.create_order(
          symbol: symbol,
          side: "SELL",
          type: "STOP_LOSS_LIMIT",
          quantity: executed_quantity || quantity,
          price: trade.stop_loss * 0.99, # Slightly below stop loss to ensure execution
          stop_price: trade.stop_loss,
          time_in_force: "GTC"
        )

        trade.update(
          stop_loss_order_id: sl_order["orderId"],
          stop_loss_data: sl_order
        )
      end

      # Notify admins about the successful trade for monitoring
      AdminNotifier.new_trade_executed(trade).deliver_later if defined?(AdminNotifier)

    rescue => e
      trade.update(
        status: "failed",
        notes: "Error: #{e.message}",
        error_data: {
          error_type: e.class.name,
          error_message: e.message,
          backtrace: e.backtrace[0..5],
          time: Time.now
        }
      )

      # Notify admins about the failed trade
      AdminNotifier.trade_failed(trade).deliver_later if defined?(AdminNotifier)

      # Re-raise the exception for retry mechanism
      raise e
    end
  end
end
