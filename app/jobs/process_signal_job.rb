class ProcessSignalJob < ApplicationJob
  queue_as :default

  # Retry failed jobs
  retry_on StandardError, wait: 5.seconds, attempts: 3

  # This job processes a signal and triggers trade execution for eligible users
  def perform(signal_id)
    signal = TradeSignal.find_by(id: signal_id)
    
    unless signal
      Rails.logger.error "ProcessSignalJob: Signal #{signal_id} not found"
      return
    end

    Rails.logger.info "ProcessSignalJob: Processing signal #{signal.id} from channel #{signal.channel.name}"

    begin
      # Process the signal to extract trading data
      signal.process_signal
      
      # Check if signal was successfully processed and is tradeable
      unless signal.tradeable?
        Rails.logger.info "ProcessSignalJob: Signal #{signal.id} is not tradeable (confidence: #{signal.confidence_score})"
        return
      end

      Rails.logger.info "ProcessSignalJob: Signal #{signal.id} processed successfully - #{signal.summary}"

      # Get the channel and check if it has subscribers
      channel = signal.channel
      
      unless channel&.users&.any?
        Rails.logger.info "ProcessSignalJob: No users subscribed to channel #{channel.name}"
        return
      end

      # Count eligible users (those with active API credentials and subscriptions)
      eligible_users_count = channel.users
                                   .joins(:api_credentials)
                                   .where(api_credentials: { platform: 'binance', active: true })
                                   .where('subscription_status = ? OR subscription_status IS NULL', 'active')
                                   .count

      if eligible_users_count == 0
        Rails.logger.info "ProcessSignalJob: No eligible users found for signal #{signal.id}"
        signal.update!(
          status: 'no_eligible_users',
          notes: 'No users with active Binance credentials and subscriptions'
        )
        return
      end

      Rails.logger.info "ProcessSignalJob: Found #{eligible_users_count} eligible users for signal #{signal.id}"

      # Queue trade execution for eligible users
      ExecuteTradeJob.perform_later(signal.id)

      # Update signal status
      signal.update!(
        status: 'queued_for_execution',
        eligible_users_count: eligible_users_count,
        queued_at: Time.current
      )

      Rails.logger.info "ProcessSignalJob: Signal #{signal.id} queued for execution"

    rescue => e
      # Handle any errors during signal processing
      handle_processing_error(signal, e)
    end
  end

  private

  def handle_processing_error(signal, error)
    Rails.logger.error "ProcessSignalJob: Error processing signal #{signal.id}: #{error.message}"
    Rails.logger.error error.backtrace.join("\n")

    # Update signal with error information
    signal.update!(
      status: 'processing_error',
      error_message: "Signal processing failed: #{error.message}",
      notes: "Error occurred during ProcessSignalJob execution"
    )

    # Notify administrators about the processing error
    if defined?(AdminNotifications)
      AdminNotifications.signal_processing_error(signal, error).deliver_later
    end

    # Re-raise for retry mechanism
    raise error
  end
end
