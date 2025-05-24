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
    # This would be replaced by actual Discord API integration
    # For now, simulating verification with realistic scenarios
    
    return { success: false, message: "Discord username is required." } if discord_username.blank?
    
    # Simulate Discord API call to check membership
    # In real implementation, this would use Discord bot API to check if user is in the server/channel
    
    # For demo: 70% success rate to simulate real verification
    is_member = rand > 0.3
    
    if is_member
      {
        success: true,
        message: "Discord membership verified successfully!"
      }
    else
      channel = Channel.find_by(id: channel_id)
      invite_link = channel&.discord_invite_link || "https://discord.gg/tramate"
      {
        success: false,
        message: "Discord username '#{discord_username}' not found in #{channel&.name || 'this'} channel.",
        invite_link: invite_link,
        help_text: "Please make sure you have joined the Discord server and are a member of the channel."
      }
    end
  end
end
