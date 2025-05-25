class TradesController < ApplicationController
  before_action :authenticate_user!
  layout 'user'
  
  def index
    @trades = current_user.trades.includes(:trade_signal, :user)
                         .order(created_at: :desc)
                         .page(params[:page]).per(20)
    
    # Filter by status if provided
    if params[:status].present?
      @trades = @trades.where(status: params[:status])
    end
    
    # Filter by date range if provided
    if params[:start_date].present? && params[:end_date].present?
      @trades = @trades.where(created_at: params[:start_date]..params[:end_date])
    end
    
    # Calculate stats
    @stats = {
      total: current_user.trades.count,
      completed: current_user.trades.where(status: 'completed').count,
      pending: current_user.trades.where(status: 'pending').count,
      failed: current_user.trades.where(status: 'failed').count
    }
    
    # Calculate success rate
    total_executed = @stats[:completed] + @stats[:failed]
    @success_rate = total_executed > 0 ? (@stats[:completed].to_f / total_executed * 100).round(2) : 0
  end
  
  def show
    @trade = current_user.trades.find(params[:id])
    @signal = @trade.trade_signal
    @channel = @signal&.channel
  rescue ActiveRecord::RecordNotFound
    redirect_to trades_path, alert: "Trade not found."
  end
end
