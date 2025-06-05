class DiscordService
  include HTTParty
  
  base_uri 'https://discord.com/api/v10'
  
  def initialize
    # Try to get config from credentials with proper fallbacks
    discord_credentials = Rails.application.credentials.discord || {}
    
    # Handle different key naming conventions
    @bot_token = discord_credentials[:bot_token] || 
                 discord_credentials[:Bot_token] || 
                 discord_credentials['bot_token'] || 
                 discord_credentials['Bot_token']
    
    @client_id = discord_credentials[:client_id] || 
                 discord_credentials['client_id']
    
    @client_secret = discord_credentials[:client_secret] || 
                     discord_credentials['client_secret']
    
    # Log configuration status
    Rails.logger.info "Discord Service initialized: bot_token=#{@bot_token.present? ? 'PRESENT' : 'MISSING'}"
    
    if @bot_token.blank?
      Rails.logger.error "Discord bot token is missing from credentials!"
    end
  end
  
  # Bot Authentication Headers
  def bot_headers
    {
      'Authorization' => "Bot #{@bot_token}",
      'Content-Type' => 'application/json'
    }
  end
  
  # OAuth2 Authentication Headers
  def oauth_headers
    {
      'Content-Type' => 'application/x-www-form-urlencoded'
    }
  end
  
  # 1. MEMBERSHIP VERIFICATION
  def verify_user_membership(guild_id, user_id)
    response = self.class.get("/guilds/#{guild_id}/members/#{user_id}", headers: bot_headers)
    
    case response.code
    when 200
      { success: true, member: response.parsed_response }
    when 404
      { success: false, error: 'User not found in server' }
    else
      { success: false, error: "API Error: #{response.code}" }
    end
  end
  
  # Check membership by Discord username (username#discriminator format)
  def check_member_by_username(guild_id:, username:)
    Rails.logger.info "Discord: Checking membership for username '#{username}' in guild '#{guild_id}'"
    
    # Validate inputs
    if guild_id.blank?
      Rails.logger.error "Discord: Guild ID is blank"
      return false
    end
    
    if username.blank?
      Rails.logger.error "Discord: Username is blank"
      return false
    end
    
    if @bot_token.blank?
      Rails.logger.error "Discord: Bot token is missing - cannot check membership"
      return false
    end
    
    # Get all guild members (this might need pagination for large servers)
    Rails.logger.info "Discord: Making API request to get guild members"
    response = self.class.get("/guilds/#{guild_id}/members?limit=1000", headers: bot_headers)
    
    Rails.logger.info "Discord API Response: Code=#{response.code}, Headers=#{response.headers.inspect}"
    
    if response.code != 200
      Rails.logger.error "Discord API Error: #{response.code} - #{response.body}"
      return false
    end
    
    members = response.parsed_response
    Rails.logger.info "Discord: Found #{members&.length || 0} members in guild"
    
    # Normalize the input username
    normalized_input = normalize_username(username)
    Rails.logger.info "Discord: Normalized input username: '#{normalized_input}'"
    
    # Search for the user by username
    found_member = members.find do |member|
      user = member['user']
      next unless user
      
      # Handle both old format (username#discriminator) and new format (@username)
      if user['discriminator'] && user['discriminator'] != '0'
        # Old format: username#discriminator
        full_username = "#{user['username']}##{user['discriminator']}"
        normalized_full = normalize_username(full_username)
        Rails.logger.debug "Discord: Checking member '#{full_username}' (normalized: '#{normalized_full}')"
        normalized_full == normalized_input
      else
        # New format: just username or @username
        normalized_username = normalize_username(user['username'])
        normalized_at_username = normalize_username("@#{user['username']}")
        Rails.logger.debug "Discord: Checking member '#{user['username']}' (normalized: '#{normalized_username}', with @: '#{normalized_at_username}')"
        normalized_username == normalized_input || normalized_at_username == normalized_input
      end
    end
    
    if found_member
      Rails.logger.info "Discord: Member found! User: #{found_member['user']['username']}##{found_member['user']['discriminator'] || '0'}"
      return true
    else
      Rails.logger.info "Discord: Member '#{username}' not found in guild '#{guild_id}'"
      return false
    end
    
  rescue => e
    Rails.logger.error "Discord member check error: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    false
  end
  
  # 2. CHANNEL PERMISSIONS CHECK
  def check_channel_permissions(guild_id, channel_id, user_id)
    response = self.class.get("/channels/#{channel_id}", headers: bot_headers)
    
    return { success: false, error: 'Channel not found' } unless response.code == 200
    
    # Check if user has access to this specific channel
    member_response = verify_user_membership(guild_id, user_id)
    return member_response unless member_response[:success]
    
    # Check channel-specific permissions
    permissions_response = self.class.get(
      "/channels/#{channel_id}/permissions/#{user_id}", 
      headers: bot_headers
    )
    
    {
      success: true,
      has_access: permissions_response.code == 200,
      member_data: member_response[:member]
    }
  end
  
  # 3. WEBHOOK MANAGEMENT
  def create_webhook(channel_id, webhook_name = 'Tramate Bot')
    payload = {
      name: webhook_name,
      avatar: nil # Can add base64 encoded image
    }
    
    response = self.class.post(
      "/channels/#{channel_id}/webhooks",
      headers: bot_headers,
      body: payload.to_json
    )
    
    if response.code == 200
      webhook = response.parsed_response
      {
        success: true,
        webhook_id: webhook['id'],
        webhook_token: webhook['token'],
        webhook_url: webhook['url']
      }
    else
      { success: false, error: "Failed to create webhook: #{response.code}" }
    end
  end
  
  # 4. GET CHANNEL MESSAGES (for monitoring)
  def get_channel_messages(channel_id, limit = 50)
    response = self.class.get(
      "/channels/#{channel_id}/messages?limit=#{limit}",
      headers: bot_headers
    )
    
    if response.code == 200
      { success: true, messages: response.parsed_response }
    else
      { success: false, error: "Failed to fetch messages: #{response.code}" }
    end
  end
  
  # 5. SEND MESSAGE TO CHANNEL
  def send_message(channel_id, content, embeds = nil)
    payload = { content: content }
    payload[:embeds] = embeds if embeds
    
    response = self.class.post(
      "/channels/#{channel_id}/messages",
      headers: bot_headers,
      body: payload.to_json
    )
    
    {
      success: response.code == 200,
      message: response.code == 200 ? response.parsed_response : response.body
    }
  end
  
  # 6. OAUTH2 USER AUTHENTICATION
  def exchange_code_for_token(code)
    payload = {
      client_id: @client_id,
      client_secret: @client_secret,
      grant_type: 'authorization_code',
      code: code,
      redirect_uri: @config['redirect_uri']
    }
    
    response = self.class.post('/oauth2/token', headers: oauth_headers, body: payload)
    
    if response.code == 200
      { success: true, token_data: response.parsed_response }
    else
      { success: false, error: response.body }
    end
  end
  
  # 7. GET USER INFO WITH OAUTH TOKEN
  def get_user_info(access_token)
    headers = {
      'Authorization' => "Bearer #{access_token}",
      'Content-Type' => 'application/json'
    }
    
    response = self.class.get('/users/@me', headers: headers)
    
    if response.code == 200
      { success: true, user: response.parsed_response }
    else
      { success: false, error: response.body }
    end
  end
  
  # 8. GET USER'S GUILDS
  def get_user_guilds(access_token)
    headers = {
      'Authorization' => "Bearer #{access_token}",
      'Content-Type' => 'application/json'
    }
    
    response = self.class.get('/users/@me/guilds', headers: headers)
    
    if response.code == 200
      { success: true, guilds: response.parsed_response }
    else
      { success: false, error: response.body }
    end
  end
  
  private
  
  # Normalize username for comparison (handle @ prefix and case sensitivity)
  def normalize_username(username)
    return '' if username.blank?
    
    # Remove @ prefix if present, convert to lowercase, and strip whitespace
    username.to_s.strip.downcase.gsub(/^@/, '')
  end
end 