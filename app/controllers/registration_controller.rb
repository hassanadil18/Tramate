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
  
  # Step 2: Discord verification and channel selection
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
    
    # Verify Discord membership
    verification_result = verify_discord_membership(discord_username, channel_id)
    
    if verification_result[:success]
      # Update session with channel and Discord info
      session[:registration][:channel_id] = channel_id
      session[:registration][:discord_username] = discord_username
      session[:registration][:current_step] = 3
      
      redirect_to registration_step3_path
    else
      flash.now[:alert] = verification_result[:message]
      @channels = Channel.all
      @selected_channel_id = channel_id
      @discord_username = discord_username
      render :step2
    end
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
    @subscriptions = Subscription.where(user_id: nil) # Available plans
  end
  
  def submit_subscription
    subscription_id = params[:subscription_id]
    
    unless subscription_id.present?
      flash.now[:alert] = "Please select a subscription plan"
      @subscriptions = Subscription.where(user_id: nil)
      render :subscription
      return
    end
    
    # Get the selected subscription
    subscription = Subscription.find(subscription_id)
    
    # Create the user with Discord ID
    @user = User.new(session[:registration][:user])
    @user.discord_id = session[:registration][:discord_username]
    
    if @user.save
      # Create user's channel access with proper schema
      if session[:registration][:channel_id].present?
        channel = Channel.find_by(id: session[:registration][:channel_id])
        if channel
          UserChannelAccess.create!(
            user: @user,
            channel: channel,
            access_type: 'subscription',
            access_start_date: Time.current,
            access_end_date: 1.year.from_now
          )
        end
      end
      
      # Create API credentials if provided
      if session[:registration][:binance_api_key].present?
        @user.api_credentials.create!(
          platform: 'binance',
          api_key: session[:registration][:binance_api_key],
          api_secret: session[:registration][:binance_api_secret],
          label: 'Binance API',
          active: true
        )
      end
      
      # Assign subscription to user
      assign_subscription_to_user(@user, subscription)
      
      # Log the user in
      session[:user_id] = @user.id
      
      # Log signup notification
      Rails.logger.info "SIGNUP NOTIFICATION: User #{@user.email} signed up at #{Time.current}"
      
      # Clear registration data
      session.delete(:registration)
      
      redirect_to dashboard_path, notice: "Account successfully created! Welcome to Tramate."
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
    # Update user with subscription info
    user.update!(
      subscription_id: subscription.id,
      subscription_status: "active",
      subscription_start_date: Time.current,
      subscription_end_date: 1.month.from_now,
      trades_count: 0
    )
  end
  
  # Discord verification logic (same as in channels controller)
  def verify_discord_membership(discord_username, channel_id)
    return { success: false, message: "Discord username is required." } if discord_username.blank?
    
    # Simulate Discord API call to check membership
    # In real implementation, this would use Discord bot API to check if user is in the server/channel
    
    # For demo: 70% success rate to simulate real verification
    is_member = rand > 0.3
    
    if is_member
      {
        success: true,
        message: "Discord membership verified successfully!"
      }
    else
      channel = Channel.find_by(id: channel_id)
      invite_link = channel&.discord_invite_link || "https://discord.gg/tramate"
      {
        success: false,
        message: "Discord username '#{discord_username}' not found in #{channel&.name || 'this'} channel. Please make sure you have joined the Discord server and are a member of the channel.",
        invite_link: invite_link
      }
    end
  end
end 