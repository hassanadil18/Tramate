class SubscriptionsController < ApplicationController
  before_action :authenticate_user!, except: [:success]
  before_action :load_subscription, only: [:new, :create]
  
  def index
    @subscriptions = Subscription.available_plans
  end

  def new
    # Initialize Checkout.com payment with credentials from Rails credentials
    checkout_api = CheckoutSdk::Builder.static_keys
      .secret_key(Rails.application.credentials.checkout[:secret_key])
      .public_key(Rails.application.credentials.checkout[:public_key])
      .environment(Rails.application.credentials.checkout[:environment] == 'production' ? 
                  CheckoutSdk::Environment::PRODUCTION : 
                  CheckoutSdk::Environment::SANDBOX)
      .build
    
    # Prepare payment request
    @payment_request = {
      source: {
        type: "card"
      },
      amount: (@subscription.price * 100).to_i, # Convert to cents
      currency: "USD",
      success_url: success_subscriptions_url,
      failure_url: new_subscription_url(subscription_id: @subscription.id),
      reference: "subscription_#{@subscription.id}_user_#{current_user.id}_#{Time.now.to_i}"
    }
    
    # For the free plan, skip payment and proceed to success
    if @subscription.price.zero?
      assign_subscription_to_user(@subscription)
      redirect_to success_subscriptions_path
      return
    end
    
    # Initialize the Checkout.com payment session
    # Note: In a real implementation, you would use environment variables for secret keys
    begin
      @payment_session = checkout_api.get_payments_client.request_payment(@payment_request)
      @payment_link = @payment_session.link
    rescue => e
      flash[:error] = "Payment initialization failed: #{e.message}"
      redirect_to subscriptions_path
    end
  end

  def create
    # This action will receive the webhook from Checkout.com
    # In a real implementation, you'd verify the webhook signature
    
    if params[:status] == "success"
      # Process successful payment
      payment = current_user.payments.create!(
        amount: @subscription.price,
        status: "completed",
        payment_gateway_id: params[:payment_id],
        description: "Subscription to #{@subscription.name} plan"
      )
      
      assign_subscription_to_user(@subscription)
      
      redirect_to success_subscriptions_path
    else
      flash[:error] = "Payment was not successful. Please try again."
      redirect_to subscriptions_path
    end
  end

  def success
    # This is where users are redirected after successful payment
    @subscription = current_user&.subscription
  end
  
  private
  
  def load_subscription
    subscription_id = params[:subscription_id] || params[:id]
    @subscription = Subscription.find_by(id: subscription_id)
    
    unless @subscription
      flash[:error] = "Subscription not found"
      redirect_to subscriptions_path
    end
  end
  
  def assign_subscription_to_user(subscription)
    # Create a subscription record for the user
    user_subscription = subscription.dup
    user_subscription.user = current_user
    user_subscription.status = "active"
    user_subscription.save!
    
    # Update user with subscription info
    current_user.update!(
      subscription_id: user_subscription.id,
      subscription_status: "active",
      subscription_start_date: Time.current,
      subscription_end_date: 1.month.from_now,
      trades_count: 0
    )
  end
end
