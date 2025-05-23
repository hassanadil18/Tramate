module Admin
  class SubscriptionsController < BaseController
    before_action :set_subscription, only: [:show, :edit, :update, :destroy]
    
    def index
      @subscriptions = Subscription.all
      
      respond_to do |format|
        format.html
        format.csv { send_data @subscriptions.to_csv, filename: "subscriptions-#{Date.today}.csv" }
      end
    end
    
    def show
    end
    
    def new
      @subscription = Subscription.new
    end
    
    def create
      @subscription = Subscription.new(subscription_params)
      
      if @subscription.save
        redirect_to admin_subscriptions_path, notice: "Subscription plan created successfully"
      else
        render :new
      end
    end
    
    def edit
    end
    
    def update
      if @subscription.update(subscription_params)
        redirect_to admin_subscriptions_path, notice: "Subscription plan updated successfully"
      else
        render :edit
      end
    end
    
    def destroy
      if @subscription.user.present?
        redirect_to admin_subscriptions_path, alert: "Cannot delete a subscription assigned to a user"
      else
        @subscription.destroy
        redirect_to admin_subscriptions_path, notice: "Subscription plan deleted successfully"
      end
    end
    
    private
    
    def set_subscription
      @subscription = Subscription.find(params[:id])
    end
    
    def subscription_params
      params.require(:subscription).permit(:name, :price, :description, :trade_limit, :status)
    end
  end
end 