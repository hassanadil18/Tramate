module Admin
  class TradesController < BaseController
    before_action :set_trade, only: [ :show, :update ]

    def index
      @trades = Trade.includes(:user, trade_signal: :channel)
                     .order(created_at: :desc)
                     .page(params[:page]).per(20)

      # Apply filters if provided
      if params[:status].present?
        @trades = @trades.where(status: params[:status])
      end

      if params[:user_id].present?
        @trades = @trades.where(user_id: params[:user_id])
      end

      if params[:channel_id].present?
        @trades = @trades.joins(trade_signal: :channel).where(trade_signals: { channel_id: params[:channel_id] })
      end

      if params[:trade_type].present?
        @trades = @trades.where(trade_type: params[:trade_type])
      end

      # For CSV export
      respond_to do |format|
        format.html
        format.csv do
          send_data @trades.to_csv,
            filename: "trades-#{Date.today}.csv",
            type: "text/csv"
        end
      end
    end

    def show
      @signal = @trade.trade_signal
      @channel = @signal&.channel
      @user = @trade.user
    end

    def update
      if @trade.update(trade_params)
        redirect_to admin_trade_path(@trade), notice: "Trade was successfully updated."
      else
        redirect_to admin_trade_path(@trade), alert: "Failed to update trade: #{@trade.errors.full_messages.join(', ')}"
      end
    end

    private

    def set_trade
      @trade = Trade.find(params[:id])
    end

    def trade_params
      params.permit(:needs_review, :review_reason, :notes)
    end
  end
end
