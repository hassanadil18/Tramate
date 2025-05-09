require 'discordrb'
require 'dotenv/load'  # Loads .env variables
require_relative '../config/environment'  # Loads Rails models

bot = Discordrb::Bot.new token: ENV['DISCORD_BOT_TOKEN'], client_id: ENV['DISCORD_CLIENT_ID']

bot.message do |event|
  puts "[#{event.user.name}] #{event.message.content}"

  # Optional: If you have a Signal model, you can save messages
  # Signal.create!(content: event.message.content, received_at: Time.now)
end

puts "Discord bot is now running..."
bot.run
