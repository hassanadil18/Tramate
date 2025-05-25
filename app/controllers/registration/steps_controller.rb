module Registration
  class StepsController < ApplicationController
    skip_before_action :authenticate_user!
    before_action :check_step_access, except: [:step1, :submit_step1, :step2, :submit_step2, :step3, :submit_step3, :subscription, :submit_subscription, :payment, :submit_payment, :payment_success]
    before_action :debug_request_info
    
    # Step 1: Basic user information
    def step1
      @user = User.new
    end
    
    def submit_step1
      @user = User.new(user_params)
      
      if @user.valid?
        # Store user data in session for later steps
        session[:registration] = {
          'user' => user_params.to_h,
          'current_step' => 2
        }
        
        redirect_to registration_step2_path
      else
        render :step1
      end
    end
    
    # Step 2: Discord verification and channel selection
    def step2
      # Initialize session if it doesn't exist (for direct access)
      if session[:registration].blank?
        session[:registration] = { 'current_step' => 2 }
      end
      
      @channels = Channel.all
      Rails.logger.info "=== STEP2 LOADED ==="
      Rails.logger.info "Session: #{session[:registration].inspect}"
    end
    
    def submit_step2
      Rails.logger.info "=== SUBMIT_STEP2 DEBUG ==="
      Rails.logger.info "Session registration data: #{session[:registration].inspect}"
      Rails.logger.info "Params: channel_id=#{params[:channel_id]}, discord_username=#{params[:discord_username]}"
      
      channel_id = params[:channel_id]
      discord_username = params[:discord_username]
      
      # Validate channel selection and Discord username
      if channel_id.blank? || discord_username.blank?
        Rails.logger.info "Validation failed: missing channel_id or discord_username"
        flash.now[:alert] = "Please select a channel and enter your Discord username"
        @channels = Channel.all
        render :step2
        return
      end
      
      # Verify Discord membership
      Rails.logger.info "Starting Discord verification..."
      verification_result = verify_discord_membership(discord_username, channel_id)
      Rails.logger.info "Verification result: #{verification_result.inspect}"
      
      if verification_result[:success]
        # Update session with channel and Discord info
        session[:registration]['channel_id'] = channel_id
        session[:registration]['discord_username'] = discord_username
        session[:registration]['current_step'] = 3
        
        # Force session save
        session.save if session.respond_to?(:save)
        
        Rails.logger.info "Verification successful, redirecting to step3"
        Rails.logger.info "Session after update: #{session[:registration].inspect}"
        redirect_to registration_step3_path
      else
        Rails.logger.info "Verification failed, rendering step2 with error"
        flash.now[:alert] = verification_result[:message]
        @channels = Channel.all
        @selected_channel_id = channel_id
        @discord_username = discord_username
        render :step2
      end
    end
    
    # Step 3: Binance API connection
    def step3
      # Initialize session if it doesn't exist
      if session[:registration].blank?
        session[:registration] = { 'current_step' => 3 }
      end
      
      Rails.logger.info "=== STEP3 LOADED ==="
      Rails.logger.info "Session: #{session[:registration].inspect}"
    end
    
    def submit_step3
      # Initialize session if it doesn't exist
      if session[:registration].blank?
        session[:registration] = { 'current_step' => 3 }
      end
      
      # Handle skip option
      if params[:skip_api] == "true"
        Rails.logger.info "User chose to skip API setup"
        session[:registration]['current_step'] = 4
        redirect_to registration_subscription_path
        return
      end
      
      # Handle API key validation
      binance_api_key = params[:binance_api_key]&.strip
      binance_api_secret = params[:binance_api_secret]&.strip
      
      # Validate required fields
      if binance_api_key.blank? || binance_api_secret.blank?
        flash.now[:alert] = "Please enter both API key and secret"
        render :step3
        return
      end
      
      # Validate API keys with real Binance API
      Rails.logger.info "Validating Binance API keys..."
      Rails.logger.info "API Key length: #{binance_api_key.length}"
      Rails.logger.info "API Secret length: #{binance_api_secret.length}"
      
      begin
        binance_service = BinanceService.new(binance_api_key, binance_api_secret)
        
        if binance_service.client.nil?
          Rails.logger.error "Failed to initialize Binance client"
          flash.now[:alert] = "Failed to initialize Binance connection. Please check if the Binance service is available."
          render :step3
          return
        end
        
        validation_result = binance_service.validate_api_keys
        
        Rails.logger.info "Binance API validation result: #{validation_result.inspect}"
        
        if validation_result[:success]
          # Ensure session registration hash exists before updating
          session[:registration] ||= {}
          
          # Store validated API credentials using string keys
          session[:registration]['binance_api_key'] = binance_api_key
          session[:registration]['binance_api_secret'] = binance_api_secret
          session[:registration]['connection_type'] = 'api_keys'
          session[:registration]['api_validated'] = true
          session[:registration]['account_info'] = {
            'account_type' => validation_result[:account_type],
            'can_trade' => validation_result[:can_trade],
            'can_withdraw' => validation_result[:can_withdraw]
          }
          session[:registration]['current_step'] = 4
          
          Rails.logger.info "API keys validated successfully, proceeding to subscription"
          Rails.logger.info "Session after API validation: #{session[:registration].inspect}"
      
          redirect_to registration_subscription_path
        else
          # Show validation error
          Rails.logger.error "API validation failed: #{validation_result[:message]}"
          flash.now[:alert] = validation_result[:message]
          render :step3
        end
        
      rescue => e
        Rails.logger.error "Error during Binance API validation: #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
        
        # Provide more specific error message based on the exception
        error_message = case e.message
        when /LoadError/, /uninitialized constant/
          "Binance API service is not properly configured. Please contact support."
        when /timeout/i, /connection/i
          "Connection timeout. Please check your internet connection and try again."
        when /ssl/i, /certificate/i
          "SSL connection error. Please try again in a few moments."
        else
          "An error occurred while validating your API keys. Please try again."
        end
        
        flash.now[:alert] = error_message
        render :step3
      end
    end
    
    # Step 4: Subscription selection
    def subscription
      # Initialize session if it doesn't exist
      if session[:registration].blank?
        session[:registration] = { 'current_step' => 4 }
      end
      
      Rails.logger.info "=== SUBSCRIPTION LOADED ==="
      Rails.logger.info "Session: #{session[:registration].inspect}"
      
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
      
      # Store selected subscription in session
      session[:registration]['selected_subscription_id'] = subscription.id
      session[:registration]['current_step'] = 5
      
      Rails.logger.info "User selected subscription: #{subscription.name} (Price: $#{subscription.price})"
      
      # If it's a free plan (Starter), complete registration immediately
      if subscription.price.zero?
        Rails.logger.info "Free plan selected, completing registration without payment"
        complete_registration(subscription)
      else
        Rails.logger.info "Paid plan selected, redirecting to payment step"
        redirect_to registration_payment_path
      end
    end
    
    # Step 5: Payment processing (for paid plans only)
    def payment
      # Initialize session if it doesn't exist
      if session[:registration].blank?
        session[:registration] = { 'current_step' => 5 }
      end
      
      subscription_id = session[:registration]['selected_subscription_id']
      unless subscription_id.present?
        flash[:alert] = "No subscription selected. Please select a plan."
        redirect_to registration_subscription_path
        return
      end
      
      @subscription = Subscription.find(subscription_id)
      
      # Redirect free plans to dashboard (shouldn't happen, but safety check)
      if @subscription.price.zero?
        complete_registration(@subscription)
        return
      end
      
      Rails.logger.info "=== PAYMENT STEP LOADED ==="
      Rails.logger.info "Subscription: #{@subscription.name} - $#{@subscription.price}"
      Rails.logger.info "Session: #{session[:registration].inspect}"
      
      # Initialize Checkout.com payment
      initialize_checkout_payment
    end
    
    def submit_payment
      subscription_id = session[:registration]['selected_subscription_id']
      unless subscription_id.present?
        flash[:alert] = "No subscription selected. Please select a plan."
        redirect_to registration_subscription_path
        return
      end
      
      subscription = Subscription.find(subscription_id)
      
      # Handle payment processing
      if params[:payment_status] == 'success' || params[:skip_payment] == 'true'
        Rails.logger.info "Payment successful for #{subscription.name} plan"
        complete_registration(subscription)
      else
        flash.now[:alert] = "Payment was not successful. Please try again."
        @subscription = subscription
        initialize_checkout_payment
        render :payment
      end
    end
    
    def payment_success
      # Handle successful payment callback from Checkout.com
      subscription_id = session[:registration]['selected_subscription_id']
      unless subscription_id.present?
        flash[:alert] = "No subscription selected. Please select a plan."
        redirect_to registration_subscription_path
        return
      end
      
      subscription = Subscription.find(subscription_id)
      Rails.logger.info "Payment success callback received for #{subscription.name} plan"
      
      complete_registration(subscription)
    end
    
    private
    
    def debug_request_info
      Rails.logger.info "=== REGISTRATION DEBUG ==="
      Rails.logger.info "Action: #{action_name}"
      Rails.logger.info "Params: #{params.inspect}"
      Rails.logger.info "Session registration: #{session[:registration].inspect}"
      Rails.logger.info "=========================="
    end
    
    def user_params
      params.require(:user).permit(:full_name, :email, :password, :password_confirmation, :terms_of_service)
    end
    
    def check_step_access
      # Ensure users can't skip steps, but allow direct access to step2 from auth form
      return redirect_to registration_step1_path unless session[:registration].present?
      
      current_step = session[:registration]['current_step'] || 1
      requested_step = extract_step_from_action
      
      # Debug logging
      Rails.logger.info "Registration check_step_access: current_step=#{current_step}, requested_step=#{requested_step}, action=#{action_name}"
      
      # Allow access to step2 and submission from auth form or normal flow
      if requested_step <= 2
        return
      end
      
      # For steps 3 and beyond, ensure proper progression
      if current_step.present? && requested_step > current_step
        Rails.logger.info "Redirecting to step #{current_step} because requested #{requested_step} > current #{current_step}"
        redirect_to send("registration_step#{current_step}_path") if current_step <= 3
        redirect_to registration_subscription_path if current_step == 4
        redirect_to registration_payment_path if current_step == 5
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
      when 'payment', 'submit_payment'
        5
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
      
      begin
        channel = Channel.find_by(id: channel_id)
        
        if channel.blank?
          return {
            success: false,
            message: "Channel not found. Please contact support.",
            help_text: "The selected channel could not be found."
          }
        end

        # Check if channel has Discord configuration
        if channel.discord_guild_id.blank?
          return {
            success: false,
            message: "Channel configuration is incomplete. Please contact support.",
            help_text: "This channel doesn't have Discord integration properly configured."
          }
        end

        # Use DiscordService for real API integration
        discord_service = DiscordService.new
        
        # Check if user is a member of the Discord server
        is_member = discord_service.check_member_by_username(
          guild_id: channel.discord_guild_id,
          username: discord_username
        )
        
        if is_member
          {
            success: true,
            message: "Discord membership verified successfully! You're now connected to #{channel.name}.",
            discord_username: discord_username
          }
        else
          invite_link = channel.discord_invite_link.presence || "https://discord.gg/tramate"
          
          {
            success: false,
            message: "Discord username '#{discord_username}' was not found in the #{channel.name} Discord server.",
            invite_link: invite_link,
            help_text: "Please make sure you have joined the Discord server first, then try again. It may take a few minutes for membership to sync.",
            action_required: "join_server"
          }
        end
        
      rescue => e
        Rails.logger.error "Discord verification error: #{e.message}"
        SystemLog.log_error("Discord verification failed for registration: #{e.message}")
        
        {
          success: false,
          message: "Unable to verify Discord membership at this time. Please try again in a few moments.",
          help_text: "If this problem persists, please contact support."
        }
      end
    end
    
    def initialize_checkout_payment
      # Initialize Checkout.com payment with credentials from Rails credentials
      begin
        checkout_credentials = Rails.application.credentials.checkout || {}
        
        # Use the actual key names from the credentials
        secret_key = checkout_credentials[:secret_key_ID] || checkout_credentials[:secret_key] || 'sk_test_dummy'
        public_key = checkout_credentials[:public_key] || 'pk_test_dummy'
        environment = checkout_credentials[:environment] || 'sandbox'
        
        Rails.logger.info "Checkout.com credentials: secret_key=#{secret_key.present? ? 'PRESENT' : 'MISSING'}, public_key=#{public_key.present? ? 'PRESENT' : 'MISSING'}"
        
        checkout_api = CheckoutSdk::Builder.static_keys
          .secret_key(secret_key)
          .public_key(public_key)
          .environment(environment == 'production' ? 
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
          success_url: registration_payment_success_url,
          failure_url: registration_payment_path,
          reference: "subscription_#{@subscription.id}_#{Time.now.to_i}"
        }
        
        # Initialize the Checkout.com payment session
        @payment_session = checkout_api.get_payments_client.request_payment(@payment_request)
        @payment_link = @payment_session.link
        
        Rails.logger.info "Checkout.com payment initialized: #{@payment_link}"
        
      rescue => e
        Rails.logger.error "Payment initialization failed: #{e.message}"
        Rails.logger.error "Error class: #{e.class}"
        flash[:alert] = "Payment system is temporarily unavailable. Please try again later."
        @payment_error = true
      end
    end
    
    def complete_registration(subscription)
      begin
        # Create the user with Discord ID and selected subscription
        @user = User.new(session[:registration]['user'])
        @user.discord_id = session[:registration]['discord_username']
        
        # Set the subscription BEFORE saving to avoid conflicts with default subscription callback
        @user.subscription = subscription
        @user.subscription_status = "active"
        @user.subscription_start_date = Time.current
        @user.subscription_end_date = 1.month.from_now
        @user.trades_count = 0
        
        Rails.logger.info "Creating user with subscription: #{subscription.name} (ID: #{subscription.id})"
      
        if @user.save
          # Create user's channel access with proper schema
          if session[:registration]['channel_id'].present?
            channel = Channel.find_by(id: session[:registration]['channel_id'])
            if channel
              UserChannelAccess.create!(
                user: @user,
                channel: channel,
                access_type: 'purchased',
                access_start_date: Time.current,
                access_end_date: 1.year.from_now
              )
            end
          end
          
          # Create API credentials based on connection type
          connection_type = session[:registration]['connection_type']
          
          if connection_type == 'api_keys' && session[:registration]['api_validated']
            # Create validated API credentials
            account_info = session[:registration]['account_info'] || {}
            
            @user.api_credentials.create!(
              platform: 'binance',
              api_key: session[:registration]['binance_api_key'],
              api_secret: session[:registration]['binance_api_secret'],
              label: 'Binance Trading API',
              active: true,
              connection_type: 'api_keys',
              account_type: account_info['account_type'],
              can_trade: account_info['can_trade'],
              can_withdraw: account_info['can_withdraw'],
              validated_at: Time.current
            )
            Rails.logger.info "Created validated Binance API credentials for user #{@user.email}"
          else
            Rails.logger.info "No API credentials created - user skipped API setup"
          end
          
          # Log the user in
          session[:user_id] = @user.id
          
          # Log signup notification
          Rails.logger.info "SIGNUP NOTIFICATION: User #{@user.email} signed up with #{subscription.name} plan at #{Time.current}"
          
          # Clear registration data
          session.delete(:registration)
          
          redirect_to user_dashboard_path, notice: "Account successfully created! Welcome to Tramate."
        else
          # Handle validation errors
          if @user.errors[:discord_id].any?
            # Discord username is already taken
            flash[:alert] = "This Discord username is already registered with Tramate. Please use a different Discord username or contact support if this is your account."
            Rails.logger.info "Registration failed: Discord username '#{session[:registration]['discord_username']}' already exists"
            
            # Redirect back to step 2 (Discord verification) to choose a different username
            session[:registration]['current_step'] = 2
            redirect_to registration_step2_path
          else
            # Other validation errors
            error_messages = @user.errors.full_messages.join(', ')
            flash[:alert] = "Error creating account: #{error_messages}"
            Rails.logger.error "Registration failed with validation errors: #{error_messages}"
            redirect_to registration_step1_path
          end
        end
        
      rescue ActiveRecord::RecordNotUnique => e
        # Handle database-level constraint violation as backup
        if e.message.include?('discord_id')
          flash[:alert] = "This Discord username is already registered with Tramate. Please use a different Discord username or contact support if this is your account."
          Rails.logger.info "Registration failed: Discord username '#{session[:registration]['discord_username']}' already exists (DB constraint)"
          
          # Redirect back to step 2 (Discord verification) to choose a different username
          session[:registration]['current_step'] = 2
          redirect_to registration_step2_path
        else
          # Other database constraint violations
          Rails.logger.error "Registration failed with database constraint: #{e.message}"
          flash[:alert] = "An error occurred during registration. Please try again or contact support."
          redirect_to registration_step1_path
        end
      rescue => e
        # Handle any other unexpected errors
        Rails.logger.error "Registration failed with unexpected error: #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
        flash[:alert] = "An unexpected error occurred during registration. Please try again or contact support."
        redirect_to registration_step1_path
      end
    end
  end
end 