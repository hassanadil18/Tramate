class DiscordAuthController < ApplicationController
  skip_before_action :authenticate_user!, only: [:authorize, :callback]
  
  def authorize
    # Redirect to Discord OAuth
    discord_auth_url = build_discord_auth_url
    redirect_to discord_auth_url, allow_other_host: true
  end
  
  def callback
    code = params[:code]
    
    if code.blank?
      flash[:alert] = "Discord authorization failed. Please try again."
      redirect_to root_path
      return
    end
    
    discord_service = DiscordService.new
    
    # Exchange code for access token
    token_response = discord_service.exchange_code_for_token(code)
    
    unless token_response[:success]
      flash[:alert] = "Failed to authenticate with Discord. Please try again."
      redirect_to root_path
      return
    end
    
    access_token = token_response[:token_data]['access_token']
    
    # Get user info
    user_response = discord_service.get_user_info(access_token)
    
    unless user_response[:success]
      flash[:alert] = "Failed to get Discord user information."
      redirect_to root_path
      return
    end
    
    discord_user = user_response[:user]
    
    # Get user's guilds
    guilds_response = discord_service.get_user_guilds(access_token)
    
    unless guilds_response[:success]
      flash[:alert] = "Failed to get Discord server information."
      redirect_to root_path
      return
    end
    
    # Store Discord info in session for setup process
    session[:discord_setup] = {
      user: discord_user,
      guilds: guilds_response[:guilds],
      access_token: access_token
    }
    
    # If user is logged in, go to channel setup
    if user_signed_in?
      redirect_to channels_path, notice: "Discord connected! You can now set up your channels."
    else
      # Store for registration process
      flash[:notice] = "Discord connected! Please complete registration."
      redirect_to auth_register_form_path
    end
  end
  
  private
  
  def build_discord_auth_url
    params = {
      client_id: Rails.application.config_for(:discord)['client_id'],
      redirect_uri: Rails.application.config_for(:discord)['redirect_uri'],
      response_type: 'code',
      scope: 'identify guilds guilds.members.read bot guilds.channels.read',
      permissions: '1108102356992' # Updated permissions with webhooks
    }
    
    "https://discord.com/oauth2/authorize?" + params.to_query
  end
end 