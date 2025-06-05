class DashboardController < ApplicationController
  before_action :authenticate_user!
  layout 'user'

  def index
    @subscription = current_user.subscription || Subscription.starter
    
    # Get user's recent trades
    @recent_trades = current_user.trades.order(created_at: :desc).limit(5)
    
    # Count trades by status
    @trades_count = {
      completed: current_user.trades.where(status: 'completed').count,
      pending: current_user.trades.where(status: 'pending').count,
      failed: current_user.trades.where(status: 'failed').count
    }
    
    # Set individual counts for the dashboard view
    @completed_trades = @trades_count[:completed]
    @pending_trades = @trades_count[:pending]
    @failed_trades = @trades_count[:failed]
    
    # Calculate success rate
    total_executed = @trades_count[:completed] + @trades_count[:failed]
    @success_rate = total_executed > 0 ? (@trades_count[:completed].to_f / total_executed * 100).round : 0
    
    # Get available/subscribed channels
    @user_channels = current_user.channels
    @available_channels = Channel.where.not(id: @user_channels.pluck(:id)).limit(3)
    @connected_channels_count = @user_channels.count
    
    # Calculate trades remaining in subscription
    @trades_remaining = current_user.trades_remaining
    
    # Get API connection status
    @api_connected = current_user.has_valid_binance_credentials?
  end

  def settings
    # User settings page
    @user = current_user
  end

  def api_connections
    # API connections management page
    @api_credentials = current_user.api_credentials
    @new_credential = ApiCredential.new
  end

  def channels
    # User's subscribed channels
    @channels = current_user.channels.includes(:signals)
  end

  def trades
    # User's trade history
    @trades = current_user.trades.order(created_at: :desc).page(params[:page]).per(20)
  end
end
