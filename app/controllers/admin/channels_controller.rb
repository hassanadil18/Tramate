module Admin
  class ChannelsController < BaseController
    before_action :set_channel, only: [:show, :edit, :update, :destroy, :setup_discord_webhook, :test_discord_connection]

    def index
      @channels = Channel.includes(:trade_signals, :user_channel_accesses)
      
      # Apply filters if present
      @channels = @channels.where(channel_type: params[:channel_type]) if params[:channel_type].present?
      @channels = @channels.where(status: params[:status]) if params[:status].present?
      @channels = @channels.where("name ILIKE ? OR description ILIKE ?", "%#{params[:search]}%", "%#{params[:search]}%") if params[:search].present?
      
      # Sort and paginate
      @channels = @channels.order(created_at: :desc).page(params[:page]).per(20)
      
      respond_to do |format|
        format.html
        format.csv { send_data Channel.to_csv, filename: "channels-#{Date.today}.csv" }
      end
    end

    def show
      @signals = @channel.trade_signals.order(created_at: :desc).limit(50)
      @trades = Trade.joins(:trade_signal)
                     .where(trade_signals: { channel_id: @channel.id })
                     .includes(:user)
                     .order(created_at: :desc)
                     .limit(20)
    end

    def new
      @channel = Channel.new
      # Set default values for Discord channels
      @channel.channel_type = 'discord'
      @channel.status = 'active'
    end

    def edit
    end

    def create
      @channel = Channel.new(channel_params)

      if @channel.save
        SystemLog.log_info("Channel created: #{@channel.name}", { channel_id: @channel.id })
        
        # Auto-setup Discord webhook if it's a Discord channel
        webhook_status = ""
        if @channel.channel_type == 'discord' && @channel.discord_channel_id.present?
          webhook_result = setup_discord_webhook_for_channel(@channel)
          if webhook_result
            webhook_status = " Discord webhook was automatically created and configured!"
          else
            webhook_status = " Note: Discord webhook setup failed - you can set it up manually from the channel details page."
          end
        end
        
        success_message = "🎉 Channel '#{@channel.name}' was successfully created!#{webhook_status}"
        flash[:success_popup] = true
        redirect_to admin_channel_path(@channel), notice: success_message
      else
        render :new
      end
    end

    def update
      if @channel.update(channel_params)
        SystemLog.log_info("Channel updated: #{@channel.name}", { channel_id: @channel.id })
        redirect_to admin_channel_path(@channel), notice: 'Channel was successfully updated.'
      else
        render :edit
      end
    end

    def destroy
      channel_name = @channel.name
      if @channel.destroy
        SystemLog.log_info("Channel deleted: #{channel_name}", { channel_id: @channel.id })
        redirect_to admin_channels_path, notice: 'Channel was successfully deleted.'
      else
        redirect_to admin_channel_path(@channel), alert: 'Failed to delete channel.'
      end
    end

    # Setup Discord webhook for a channel
    def setup_discord_webhook
      discord_service = DiscordService.new
      
      result = discord_service.create_webhook(@channel.discord_channel_id, "Tramate-#{@channel.name}")
      
      if result[:success]
        @channel.update!(
          discord_webhook_url: result[:webhook_url]
        )
        
        SystemLog.log_info("Discord webhook created for channel: #{@channel.name}", { 
          channel_id: @channel.id,
          webhook_url: result[:webhook_url]
        })
        
        redirect_to admin_channel_path(@channel), notice: 'Discord webhook successfully created!'
      else
        redirect_to admin_channel_path(@channel), alert: "Failed to create Discord webhook: #{result[:error]}"
      end
    end

    # Test Discord connection
    def test_discord_connection
      discord_service = DiscordService.new
      
      # Test by getting channel info
      result = discord_service.get_channel_messages(@channel.discord_channel_id, 1)
      
      if result[:success]
        redirect_to admin_channel_path(@channel), notice: 'Discord connection successful! Bot can access this channel.'
      else
        redirect_to admin_channel_path(@channel), alert: "Discord connection failed: #{result[:error]}"
      end
    end

    private

    def set_channel
      @channel = Channel.find(params[:id])
    end

    def channel_params
      params.require(:channel).permit(
        :name,
        :channel_type,
        :status,
        :webhook_url,
        :api_key,
        :description,
        :signal_format,
        :signal_template,
        :discord_channel_id,
        :discord_guild_id,
        :discord_webhook_url,
        :discord_bot_permissions,
        :discord_invite_link,
        :price_per_month,
        :tramate_resell_enabled,
        :logo_url
      )
    end

    def setup_discord_webhook_for_channel(channel)
      return false unless channel.discord_channel_id.present?
      
      discord_service = DiscordService.new
      result = discord_service.create_webhook(channel.discord_channel_id, "Tramate-#{channel.name}")
      
      if result[:success]
        channel.update(discord_webhook_url: result[:webhook_url])
        SystemLog.log_info("Auto-created Discord webhook for channel: #{channel.name}", { 
          channel_id: channel.id,
          webhook_url: result[:webhook_url]
        })
        true
      else
        false
      end
    end
  end
end
