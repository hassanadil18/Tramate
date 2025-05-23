module Admin
  class DashboardController < BaseController
    def index
      # Overview statistics
      @users_count = User.count
      @active_subscriptions = Subscription.where(user_id: User.pluck(:id)).where(status: 'active').count
      @total_trades = Trade.count
      @completed_trades = Trade.completed.count
      @failed_trades = Trade.failed.count
      @channels_count = Channel.count
      
      # Success rate
      total_executed = @completed_trades + @failed_trades
      @success_rate = total_executed > 0 ? (@completed_trades.to_f / total_executed * 100).round : 0
      
      # Recent trades
      @recent_trades = Trade.order(created_at: :desc).limit(10)
      
      # Recent users
      @recent_users = User.order(created_at: :desc).limit(5)
      
      # Revenue stats - from subscriptions
      @revenue_this_month = Payment.where(status: 'completed')
                                .where('created_at >= ?', Time.current.beginning_of_month)
                                .sum(:amount)
      
      # Get system logs
      @recent_logs = SystemLog.order(created_at: :desc).limit(5)
    end

    def users
      # User management for admin
      @users = User.order(created_at: :desc).page(params[:page]).per(20)
    end

    def channels
      # Channel management for admin
      @channels = Channel.includes(:trade_signals).order(created_at: :desc).page(params[:page]).per(20)
    end

    def payments
      # Payment management for admin
      @payments = Payment.includes(:user).order(created_at: :desc).page(params[:page]).per(20)
    end

    def trades
      # Trade management for admin
      @trades = Trade.includes(:user).order(created_at: :desc).page(params[:page]).per(20)
    end

    def logs
      @logs = SystemLog.order(created_at: :desc).page(params[:page]).per(50)
    end
  end
end
