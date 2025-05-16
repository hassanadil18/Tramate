module Admin
  class DashboardController < ApplicationController
    before_action :authenticate_user!
    before_action :authenticate_admin!

    def index
      # The view will handle the data fetching directly
    end

    def users
      # User management for admin
      @users = User.order(created_at: :desc).page(params[:page]).per(20)
    end

    def channels
      # Channel management for admin
      @channels = Channel.includes(:signals).order(created_at: :desc).page(params[:page]).per(20)
    end

    def payments
      # Payment management for admin
      @payments = Payment.includes(:user).order(created_at: :desc).page(params[:page]).per(20)
    end

    def trades
      # Trade management for admin
      @trades = Trade.includes(:user, :channel).order(created_at: :desc).page(params[:page]).per(20)
    end

    def logs
      @logs = SystemLog.order(created_at: :desc).page(params[:page]).per(50)
    end

    private

    def authenticate_admin!
      unless current_user&.admin?
        flash[:alert] = "You are not authorized to access this section."
        redirect_to root_path
      end
    end
  end
end
