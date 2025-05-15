class DashboardController < ApplicationController
  before_action :authenticate_user!

  def index
    # Dashboard data for authenticated users
    @trades = current_user.trades.order(created_at: :desc).limit(5) if defined?(current_user.trades)
    @channels = current_user.channels.includes(:signals).limit(5) if defined?(current_user.channels)
    @connected_apis = current_user.api_credentials.active
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
