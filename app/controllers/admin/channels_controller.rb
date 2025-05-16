module Admin
  class ChannelsController < ApplicationController
    before_action :authenticate_user!
    before_action :authenticate_admin!
    before_action :set_channel, only: [:show, :edit, :update, :destroy]

    def index
      @channels = Channel.includes(:signals, :channel_accesses)
                        .order(created_at: :desc)
                        .page(params[:page]).per(20)
    end

    def show
      @signals = @channel.signals.order(created_at: :desc).limit(50)
      @trades = Trade.joins(:signal)
                     .where(signals: { channel_id: @channel.id })
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
        :signal_template
      )
    end

    def authenticate_admin!
      unless current_user&.admin?
        flash[:alert] = "You are not authorized to access this section."
        redirect_to root_path
      end
    end
  end
end
