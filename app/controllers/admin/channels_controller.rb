module Admin
  class ChannelsController < BaseController
    before_action :set_channel, only: [:show, :edit, :update, :destroy]

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
    end

    def edit
    end

    def create
      @channel = Channel.new(channel_params)

      if @channel.save
        SystemLog.log_info("Channel created: #{@channel.name}", { channel_id: @channel.id })
        redirect_to admin_channel_path(@channel), notice: 'Channel was successfully created.'
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
        :price_per_month,
        :tramate_resell_enabled,
        :logo_url
      )
    end
  end
end
