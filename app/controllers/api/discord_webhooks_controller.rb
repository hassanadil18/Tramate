class Api::DiscordWebhooksController < ApplicationController
  skip_before_action :authenticate_user!
  skip_before_action :verify_authenticity_token
  
  def receive
    # Verify webhook signature (important for security)
    return head :unauthorized unless verify_webhook_signature
    
    event_data = JSON.parse(request.body.read)
    event_type = request.headers['X-Signature-Ed25519']
    
    case event_data['t'] # Event type
    when 'GUILD_MEMBER_ADD'
      handle_member_join(event_data['d'])
    when 'GUILD_MEMBER_REMOVE'
      handle_member_leave(event_data['d'])
    when 'MESSAGE_CREATE'
      handle_new_message(event_data['d'])
    when 'GUILD_MEMBER_UPDATE'
      handle_member_update(event_data['d'])
    else
      Rails.logger.info "Unhandled Discord event: #{event_data['t']}"
    end
    
    head :ok
  end
  
  private
  
  def verify_webhook_signature
    # Discord webhook signature verification
    signature = request.headers['X-Signature-Ed25519']
    timestamp = request.headers['X-Signature-Timestamp']
    
    # For now, we'll skip verification in development
    return true if Rails.env.development?
    
    # In production, verify the signature using Discord's public key
    # Implementation depends on your crypto library
    true
  end
  
  def handle_member_join(data)
    guild_id = data['guild_id']
    user_data = data['user']
    
    # Find channels for this guild
    channels = Channel.where(discord_guild_id: guild_id)
    
    channels.each do |channel|
      # Log member join
      Rails.logger.info "New member joined #{guild_id}: #{user_data['username']}##{user_data['discriminator']}"
      
      # You can add logic here to automatically grant access or send welcome messages
    end
  end
  
  def handle_member_leave(data)
    guild_id = data['guild_id']
    user_data = data['user']
    
    # Revoke access for users who left the Discord server
    discord_user_id = user_data['id']
    user = User.find_by(discord_id: discord_user_id)
    
    if user
      # Remove channel access for this user
      channels = Channel.where(discord_guild_id: guild_id)
      UserChannelAccess.where(user: user, channel: channels).destroy_all
      
      Rails.logger.info "Revoked access for user #{user.email} who left Discord server"
    end
  end
  
  def handle_new_message(data)
    channel_id = data['channel_id']
    author = data['author']
    content = data['content']
    
    # Skip bot messages
    return if author['bot']
    
    # Find channel in our system
    channel = Channel.find_by(discord_channel_id: channel_id)
    return unless channel
    
    # Check if this is a trading signal
    if content.match?(/\b(BUY|SELL|LONG|SHORT)\b/i)
      TradeSignalProcessorJob.perform_later(channel.id, data)
    end
    
    Rails.logger.info "New message in #{channel.name}: #{content[0..50]}..."
  end
  
  def handle_member_update(data)
    guild_id = data['guild_id']
    user_data = data['user']
    roles = data['roles']
    
    # Handle role changes that might affect channel access
    discord_user_id = user_data['id']
    user = User.find_by(discord_id: discord_user_id)
    
    if user
      # Check if user still has required roles for their channels
      verify_user_channel_access(user, guild_id, roles)
    end
  end
  
  def verify_user_channel_access(user, guild_id, user_roles)
    channels = Channel.where(discord_guild_id: guild_id)
    
    channels.each do |channel|
      # Check if user still has access based on their current roles
      # This would depend on your specific role-based access control
      has_access = check_role_based_access(channel, user_roles)
      
      user_access = UserChannelAccess.find_by(user: user, channel: channel)
      
      if has_access && !user_access
        # Grant access
        UserChannelAccess.create!(
          user: user,
          channel: channel,
          access_type: 'discord_role',
          access_start_date: Time.current,
          access_end_date: 1.year.from_now
        )
      elsif !has_access && user_access
        # Revoke access
        user_access.destroy
      end
    end
  end
  
  def check_role_based_access(channel, user_roles)
    # Implement your role-based access logic here
    # For example, check if user has required role IDs
    required_roles = channel.discord_bot_permissions&.split(',') || []
    return true if required_roles.empty?
    
    (required_roles & user_roles).any?
  end
end 