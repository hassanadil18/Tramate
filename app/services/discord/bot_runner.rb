require "discordrb"
require "dotenv/load"  # Loads .env variables
require_relative "../config/environment"  # Loads Rails models

bot = Discordrb::Bot.new token: ENV["DISCORD_BOT_TOKEN"], client_id: ENV["DISCORD_CLIENT_ID"]

bot.message do |event|
  puts "[#{event.user.name}] #{event.message.content}"

  # Get the channel ID from the Discord message
  discord_channel_id = event.channel.id.to_s

  # Find the corresponding Channel in our database
  channel = Channel.find_by(discord_channel_id: discord_channel_id)

  if channel
    # Create a new Signal associated with the channel
    signal = channel.signals.create!(
      message_content: event.message.content,
      parsed_data: {} # Will be filled by process_signal
    )

    # Process the signal to extract trading information
    signal.process_signal

    # If signal was successfully parsed, queue up processing for trades
    if signal.parsed_data.present? && signal.parsed_data[:coin].present?
      # Queue the signal processing job which will create trades for subscribers
      ProcessSignalJob.perform_later(signal.id)

      puts "Signal saved and queued for processing. Channel: #{channel.name}, Coin: #{signal.parsed_data[:coin]}"
    else
      puts "Message didn't contain valid trading signal format. Channel: #{channel.name}"
    end
  else
    puts "No matching channel found for Discord channel ID: #{discord_channel_id}"
  end
end

puts "Discord bot is now running..."
bot.run
