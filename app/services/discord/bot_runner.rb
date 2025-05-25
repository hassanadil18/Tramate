require "discordrb"
require "dotenv/load"  # Loads .env variables
require_relative "../../config/environment"  # Loads Rails models

bot = Discordrb::Bot.new token: ENV["DISCORD_BOT_TOKEN"], client_id: ENV["DISCORD_CLIENT_ID"]

bot.message do |event|
  puts "[#{event.user.name}] #{event.message.content}"

  # Get the channel ID from the Discord message
  discord_channel_id = event.channel.id.to_s

  # Find the corresponding Channel in our database
  channel = Channel.find_by(discord_channel_id: discord_channel_id)

  if channel
    # Create a new TradeSignal associated with the channel
    signal = channel.trade_signals.create!(
      message_content: event.message.content,
      parsed_data: {} # Will be filled by process_signal
    )

    Rails.logger.info "Signal created: #{signal.id} for channel: #{channel.name}"
    puts "Signal saved for processing. Channel: #{channel.name}, Message: #{event.message.content[0..100]}"
    
    # The signal will be automatically processed via the after_create callback
    # which triggers ProcessSignalJob.perform_later(signal.id)
    
  else
    puts "No matching channel found for Discord channel ID: #{discord_channel_id}"
  end
end

puts "Discord bot is now running..."
bot.run
