require "discordrb"
require_relative "../../config/environment"  # Loads Rails models

# Get Discord credentials from Rails credentials
discord_credentials = Rails.application.credentials.discord || {}
bot_token = discord_credentials[:bot_token] || discord_credentials[:Bot_token]
client_id = discord_credentials[:client_id]

if bot_token.blank?
  puts "❌ Discord bot token not found in Rails credentials!"
  puts "Please add discord.bot_token to your credentials."
  exit 1
end

if client_id.blank?
  puts "❌ Discord client ID not found in Rails credentials!"
  puts "Please add discord.client_id to your credentials."
  exit 1
end

puts "🤖 Initializing Discord bot..."
puts "Bot Token: #{bot_token[0..10]}..."
puts "Client ID: #{client_id}"

bot = Discordrb::Bot.new token: bot_token, client_id: client_id

bot.message do |event|
  puts "[#{Time.current}] [#{event.user.name}] #{event.message.content}"

  # Skip bot messages to avoid loops
  next if event.user.bot_account?

  # Get the channel ID from the Discord message
  discord_channel_id = event.channel.id.to_s

  # Find the corresponding Channel in our database
  channel = Channel.find_by(discord_channel_id: discord_channel_id)

  if channel
    puts "📡 Found matching channel: #{channel.name}"
    
    # Check if this looks like a trading signal
    content = event.message.content
    if content.match?(/\b(BUY|SELL|LONG|SHORT|ENTRY|TP|SL|TARGET|STOP)\b/i)
      puts "🚀 Trading signal detected!"
      
    # Create a new TradeSignal associated with the channel
    signal = channel.trade_signals.create!(
        message_content: content,
        parsed_data: {}, # Will be filled by process_signal
        status: 'pending'
    )

    Rails.logger.info "Signal created: #{signal.id} for channel: #{channel.name}"
      puts "✅ Signal saved for processing. ID: #{signal.id}"
      puts "📊 Message: #{content[0..100]}#{'...' if content.length > 100}"
    
    # The signal will be automatically processed via the after_create callback
      # which triggers TradeSignalProcessorJob.perform_later(signal.id)
    else
      puts "💬 Regular message (not a trading signal)"
    end
  else
    puts "❌ No matching channel found for Discord channel ID: #{discord_channel_id}"
    puts "Available channels: #{Channel.where(channel_type: 'discord').pluck(:name, :discord_channel_id).inspect}"
  end
end

bot.ready do |event|
  puts "🟢 Discord bot is now connected and running!"
  puts "👀 Monitoring channels for trading signals..."
  puts "🔍 Watching for keywords: BUY, SELL, LONG, SHORT, ENTRY, TP, SL, TARGET, STOP"
  puts "📋 Configured channels:"
  Channel.where(channel_type: 'discord').each do |channel|
    puts "   - #{channel.name} (ID: #{channel.discord_channel_id})"
  end
end

bot.disconnected do |event|
  puts "🔴 Discord bot disconnected!"
end

puts "🚀 Starting Discord bot for real-time message processing..."
bot.run
