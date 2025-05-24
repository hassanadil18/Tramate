class ChannelsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_channel, only: [:show, :create, :destroy, :verify_discord, :complete_connection]

  def index
    @channels = Channel.all
    @user_channels = current_user.channels
    @available_channels = @channels - @user_channels
  end

  def show
    @is_connected = current_user.channels.include?(@channel)
  end

  # First step: Show Discord verification form
  def create
    @channel = Channel.find(params[:id] || params[:channel_id])
    
    if current_user.channels.include?(@channel)
      redirect_to channels_path, alert: 'You are already connected to this channel.'
      return
    end

    # Store channel_id in session for verification process
    session[:connecting_channel_id] = @channel.id
    
    # Render Discord verification form instead of directly connecting
    respond_to do |format|
      format.html { redirect_to verify_discord_channel_path(@channel) }
      format.json { render json: { success: true, verification_required: true, channel_id: @channel.id } }
    end
  end

  # Show Discord verification form
  def verify_discord
    unless session[:connecting_channel_id] == @channel.id
      redirect_to channels_path, alert: 'Invalid connection session. Please try again.'
      return
    end
  end

  # Process Discord verification and complete connection
  def complete_connection
    discord_username = params[:discord_username]
    
    unless session[:connecting_channel_id] == @channel.id
      render json: { success: false, message: 'Invalid connection session. Please try again.' }
      return
    end

    # Verify Discord membership using the existing auth method
    verification_result = verify_discord_membership(discord_username, @channel.id)
    
    if verification_result[:success]
      # Create user channel access with proper schema
      user_channel_access = UserChannelAccess.new(
        user: current_user,
        channel: @channel,
        access_type: 'subscription', # or 'premium', 'free', etc.
        access_start_date: Time.current,
        access_end_date: 1.year.from_now # Default to 1 year access
      )

      if user_channel_access.save
        # Update user's discord_id if not already set
        current_user.update(discord_id: discord_username) if current_user.discord_id.blank?
        
        # Clear session
        session.delete(:connecting_channel_id)
        
        SystemLog.log_info("User #{current_user.email} connected to channel #{@channel.name} after Discord verification")
        
        respond_to do |format|
          format.html { redirect_to channels_path, notice: "Successfully connected to #{@channel.name}!" }
          format.json { render json: { success: true, message: "Successfully connected to #{@channel.name}!" } }
        end
      else
        respond_to do |format|
          format.html { redirect_to verify_discord_channel_path(@channel), alert: 'Failed to connect to channel. Please try again.' }
          format.json { render json: { success: false, message: 'Failed to connect to channel. Please try again.' } }
        end
      end
    else
      respond_to do |format|
        format.html { 
          flash[:alert] = verification_result[:message]
          render :verify_discord 
        }
        format.json { render json: verification_result }
      end
    end
  end

  def destroy
    @channel = Channel.find(params[:id])
    user_channel_access = UserChannelAccess.find_by(user: current_user, channel: @channel)
    
    if user_channel_access&.destroy
      SystemLog.log_info("User #{current_user.email} disconnected from channel #{@channel.name}")
      redirect_to channels_path, notice: "Successfully disconnected from #{@channel.name}!"
    else
      redirect_to channels_path, alert: 'Failed to disconnect from channel.'
    end
  end

  private

  def set_channel
    @channel = Channel.find(params[:id]) if params[:id]
  end

  # Discord verification logic (reused from auth controller)
  def verify_discord_membership(discord_username, channel_id)
    return { success: false, message: "Discord username is required." } if discord_username.blank?
    
    begin
      channel = Channel.find_by(id: channel_id)
      
      if channel.blank? || channel.discord_guild_id.blank?
        return {
          success: false,
          message: "Channel configuration is incomplete. Please contact support.",
          help_text: "This channel doesn't have Discord integration properly configured."
        }
      end

      # Use DiscordService for real API integration
      discord_service = DiscordService.new
      
      # Check if user is a member of the Discord server
      is_member = discord_service.check_member_by_username(
        guild_id: channel.discord_guild_id,
        username: discord_username
      )
      
      if is_member
        {
          success: true,
          message: "Discord membership verified successfully! You're now connected to #{channel.name}.",
          discord_username: discord_username
        }
      else
        invite_link = channel.discord_invite_link.presence || "https://discord.gg/tramate"
        
        {
          success: false,
          message: "Discord username '#{discord_username}' was not found in the #{channel.name} Discord server.",
          invite_link: invite_link,
          help_text: "Please make sure you have joined the Discord server first, then try again. It may take a few minutes for membership to sync.",
          action_required: "join_server"
        }
      end
      
    rescue => e
      Rails.logger.error "Discord verification error: #{e.message}"
      SystemLog.log_error("Discord verification failed for user #{current_user.email}: #{e.message}")
      
      {
        success: false,
        message: "Unable to verify Discord membership at this time. Please try again in a few moments.",
        help_text: "If this problem persists, please contact support."
      }
    end
  end
end
