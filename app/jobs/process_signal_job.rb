class ProcessSignalJob < ApplicationJob
  queue_as :default

  # This job processes a signal and creates trades for users subscribed to the channel
  def perform(signal_id)
    signal = Signal.find_by(id: signal_id)
    return unless signal && signal.parsed_data.present?

    # Get the channel and its subscribers
    channel = signal.channel
    return unless channel

    # Process trades for each user who has access to this channel
    channel.users.each do |user|
      # Find active Binance API credentials for this user
      binance_credentials = user.api_credentials.binance.active.first
      next unless binance_credentials

      # Create a trade record
      trade = Trade.create!(
        user: user,
        signal: signal,
        status: "pending",
        coin: signal.parsed_data[:coin],
        entry_price: signal.parsed_data[:entry_price],
        target_price: signal.parsed_data[:take_profit],
        stop_loss: signal.parsed_data[:stop_loss]
      )

      # Queue the actual trade execution as a separate job
      ExecuteTradeJob.perform_later(trade.id, binance_credentials.id)
    end
  end
end
