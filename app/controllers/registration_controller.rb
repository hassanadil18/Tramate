class RegistrationController < ApplicationController
  skip_before_action :authenticate_user!
  before_action :check_step_access, except: [:step1, :submit_step1]
  
  # Step 1: Basic user information
  def step1
    @user = User.new
  end
  
  def submit_step1
    @user = User.new(user_params)
    
    if @user.valid?
      # Store user data in session for later steps
      session[:registration] = {
        user: user_params.to_h,
        current_step: 2
      }
      
      redirect_to registration_step2_path
    else
      render :step1
    end
  end
  
  # Step 2: Discord verification
  def step2
    @channels = Channel.all
  end
  
  def submit_step2
    channel_id = params[:channel_id]
    discord_username = params[:discord_username]
    
    # Validate channel selection and Discord username
    if channel_id.blank? || discord_username.blank?
      flash.now[:alert] = "Please select a channel and enter your Discord username"
      @channels = Channel.all
      render :step2
      return
    end
    
    # Update session with channel and Discord info
    session[:registration][:channel_id] = channel_id
    session[:registration][:discord_username] = discord_username
    session[:registration][:current_step] = 3
    
    redirect_to registration_step3_path
  end
  
  # Step 3: Binance API connection
  def step3
  end
  
  def submit_step3
    binance_api_key = params[:binance_api_key]
    binance_api_secret = params[:binance_api_secret]
    
    # Validate Binance API credentials (optional)
    if binance_api_key.present? && binance_api_secret.blank?
      flash.now[:alert] = "Please enter both API key and secret, or leave both blank"
      render :step3
      return
    end
    
    # Update session with Binance API info
    session[:registration][:binance_api_key] = binance_api_key
    session[:registration][:binance_api_secret] = binance_api_secret
    session[:registration][:current_step] = 4
    
    redirect_to registration_subscription_path
  end
  
  # Step 4: Subscription selection
  def subscription
    @subscriptions = Subscription.available_plans
  end
  
  def submit_subscription
    subscription_id = params[:subscription_id]
    
    unless subscription_id.present?
      flash.now[:alert] = "Please select a subscription plan"
      @subscriptions = Subscription.available_plans
      render :subscription
      return
    end
    
    # Get the selected subscription
    subscription = Subscription.find(subscription_id)
    
    # Create the user
    @user = User.new(session[:registration][:user])
    @user.discord_username = session[:registration][:discord_username]
    
    if @user.save
      # Create user's channel access
      if session[:registration][:channel_id].present?
        channel = Channel.find_by(id: session[:registration][:channel_id])
        @user.user_channel_accesses.create(channel: channel) if channel
      end
      
      # Create API credentials if provided
      if session[:registration][:binance_api_key].present?
        @user.api_credentials.create(
          platform: 'binance',
          api_key: session[:registration][:binance_api_key],
          api_secret: session[:registration][:binance_api_secret],
          label: 'Binance API',
          active: true
        )
      end
      
      # Log the user in
      session[:user_id] = @user.id
      
      # Clear registration data
      session.delete(:registration)
      
      # If free plan, assign directly
      if subscription.price.zero?
        assign_subscription_to_user(@user, subscription)
        redirect_to success_subscriptions_path
      else
        # For paid plans, redirect to payment
        redirect_to new_subscription_path(subscription_id: subscription.id)
      end
    else
      flash[:alert] = "Error creating account: #{@user.errors.full_messages.join(', ')}"
      redirect_to registration_step1_path
    end
  end
  
  private
  
  def user_params
    params.require(:user).permit(:full_name, :email, :password, :password_confirmation, :terms_of_service)
  end
  
  def check_step_access
    # Ensure users can't skip steps
    return redirect_to registration_step1_path unless session[:registration].present?
    
    current_step = session[:registration][:current_step]
    requested_step = extract_step_from_action
    
    if requested_step > current_step
      redirect_to send("registration_step#{current_step}_path")
    end
  end
  
  def extract_step_from_action
    case action_name
    when 'step1', 'submit_step1'
      1
    when 'step2', 'submit_step2'
      2
    when 'step3', 'submit_step3'
      3
    when 'subscription', 'submit_subscription'
      4
    else
      1
    end
  end
  
  def assign_subscription_to_user(user, subscription)
    # Create a subscription record for the user
    user_subscription = subscription.dup
    user_subscription.user = user
    user_subscription.status = "active"
    user_subscription.save!
    
    # Update user with subscription info
    user.update!(
      subscription_id: user_subscription.id,
      subscription_status: "active",
      subscription_start_date: Time.current,
      subscription_end_date: 1.month.from_now,
      trades_count: 0
    )
  end
end 