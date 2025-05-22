class Admin::SubscriptionsController < ApplicationController
  before_action :require_admin
  before_action :set_subscription, only: [:show, :edit, :update, :destroy]
  
  def index
    @subscriptions = Subscription.all
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
  
  def require_admin
    unless current_user&.admin?
      flash[:alert] = "You are not authorized to access this page"
      redirect_to root_path
    end
  end
end 