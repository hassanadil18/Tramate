class SubscriptionsController < ApplicationController
  before_action :authenticate_user!, except: [:success]
  before_action :load_subscription, only: [:new, :create, :select]
  layout 'user'
  
  def index
    @subscriptions = Subscription.available_plans
    @current_subscription = current_user.subscription
  end

  def select
    # Handle subscription selection from dashboard
    if @subscription.price.zero?
      # Free plan - assign immediately
      assign_subscription_to_user(@subscription)
      flash[:success] = "Successfully switched to #{@subscription.name} plan!"
      redirect_to subscriptions_path
    else
      # Paid plan - redirect to payment
      redirect_to new_subscription_path(subscription_id: @subscription.id)
    end
  end

  def new
    # For the free plan, skip payment and proceed to success
    if @subscription.price.zero?
      assign_subscription_to_user(@subscription)
      redirect_to success_subscription_path(@subscription)
      return
    end

    # Initialize Checkout.com payment with credentials from Rails credentials
    begin
      checkout_credentials = Rails.application.credentials.checkout || {}
      
      # Check if credentials are available
      secret_key = checkout_credentials[:secret_key_ID] || checkout_credentials[:secret_key]
      public_key = checkout_credentials[:public_key]
      
      Rails.logger.info "Checkout credentials check: secret_key present=#{secret_key.present?}, public_key present=#{public_key.present?}"
      
      unless secret_key.present? && public_key.present?
        # Show payment form without SDK integration
        @payment_error = "Payment gateway configuration incomplete"
        Rails.logger.error "Missing checkout credentials: secret_key=#{secret_key.present?}, public_key=#{public_key.present?}"
        render :new
        return
      end
      
      # Create payment session using direct HTTP API
      Rails.logger.info "Creating payment session using Checkout.com API"
      
      payment_data = {
        amount: (@subscription.price * 100).to_i, # Convert to cents
        currency: "USD",
        reference: "subscription_#{@subscription.id}_user_#{current_user.id}_#{Time.now.to_i}",
        description: "#{@subscription.name} Plan Subscription",
        success_url: success_subscription_url(@subscription),
        failure_url: new_subscription_url(subscription_id: @subscription.id),
        customer: {
          email: current_user.email,
          name: current_user.full_name
        }
      }
      
      # For now, create a simple payment form instead of using the complex SDK
      # This will show a form that can be used with Checkout.com's payment elements
      @payment_data = payment_data
      @public_key = public_key
      
      Rails.logger.info "Payment data prepared: #{payment_data.inspect}"
      
    rescue => e
      Rails.logger.error "Payment initialization failed: #{e.message}"
      Rails.logger.error "Error class: #{e.class}"
      Rails.logger.error e.backtrace.join("\n")
      
      # Show payment form with error message instead of redirecting
      @payment_error = "Payment system temporarily unavailable: #{e.message}"
      render :new
    end
  end

  def create
    # Handle payment processing from Checkout.com
    subscription_id = params[:subscription_id]
    payment_token = params[:payment_token]
    
    @subscription = Subscription.find_by(id: subscription_id)
    unless @subscription
      render json: { success: false, error: "Subscription not found" }
      return
    end
    
    if payment_token.present?
      # Process payment with Checkout.com API
      begin
        checkout_credentials = Rails.application.credentials.checkout || {}
        secret_key = checkout_credentials[:secret_key_ID] || checkout_credentials[:secret_key]
        
        # Create payment using Checkout.com API
        payment_result = process_checkout_payment(payment_token, @subscription, secret_key)
        
        if payment_result[:success]
          # Create payment record
          payment = current_user.payments.create!(
            amount: @subscription.price,
            status: "completed",
            payment_gateway_id: payment_result[:payment_id],
            notes: "Subscription to #{@subscription.name} plan"
          )
          
          # Assign subscription to user
          assign_subscription_to_user(@subscription)
          
          render json: { 
            success: true, 
            redirect_url: success_subscription_path(@subscription) 
          }
        else
          render json: { 
            success: false, 
            error: payment_result[:error] || "Payment failed" 
          }
        end
        
      rescue => e
        Rails.logger.error "Payment processing failed: #{e.message}"
        render json: { 
          success: false, 
          error: "Payment processing failed. Please try again." 
        }
      end
    elsif params[:status] == "success"
      # Handle test/demo payments and checkout.com payments
      payment_id = params[:payment_id] || "test_payment_#{Time.now.to_i}"
      payment_method = params[:payment_method] || "test"
      
      payment = current_user.payments.create!(
        amount: @subscription.price,
        status: "completed",
        payment_gateway_id: payment_id,
        notes: "Subscription to #{@subscription.name} plan (#{payment_method})"
      )
      
      assign_subscription_to_user(@subscription)
      
      if request.format.json?
        render json: { 
          success: true, 
          redirect_url: success_subscription_path(@subscription) 
        }
      else
        redirect_to success_subscription_path(@subscription)
      end
    else
      error_message = "Payment was not successful. Please try again."
      
      if request.format.json?
        render json: { success: false, error: error_message }
      else
        flash[:error] = error_message
        redirect_to subscriptions_path
      end
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
    # Update user with subscription info only - don't touch other fields that might cause validation errors
    current_user.update_columns(
      subscription_id: subscription.id,
      subscription_status: "active",
      subscription_start_date: Time.current,
      subscription_end_date: 1.month.from_now,
      trades_count: 0
    )
  end
  
  def process_checkout_payment(payment_token, subscription, secret_key)
    require 'net/http'
    require 'json'
    
    begin
      # Checkout.com API endpoint for sandbox
      uri = URI('https://api.sandbox.checkout.com/payments')
      
      # Prepare payment data
      payment_data = {
        source: {
          type: "token",
          token: payment_token
        },
        amount: (subscription.price * 100).to_i, # Convert to cents
        currency: "USD",
        reference: "subscription_#{subscription.id}_user_#{current_user.id}_#{Time.now.to_i}",
        description: "#{subscription.name} Plan Subscription",
        customer: {
          email: current_user.email,
          name: current_user.full_name
        }
      }
      
      # Create HTTP request
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      
      request = Net::HTTP::Post.new(uri)
      request['Authorization'] = "Bearer #{secret_key}"
      request['Content-Type'] = 'application/json'
      request.body = payment_data.to_json
      
      Rails.logger.info "Sending payment request to Checkout.com: #{payment_data.inspect}"
      
      # Send request
      response = http.request(request)
      
      Rails.logger.info "Checkout.com response code: #{response.code}"
      Rails.logger.info "Checkout.com response body: #{response.body}"
      
      # Handle empty response
      if response.body.nil? || response.body.strip.empty?
        Rails.logger.error "Empty response from Checkout.com API"
        return {
          success: false,
          error: "Payment gateway returned empty response"
        }
      end
      
      begin
        response_data = JSON.parse(response.body)
      rescue JSON::ParserError => e
        Rails.logger.error "Failed to parse Checkout.com response: #{e.message}"
        Rails.logger.error "Response body was: #{response.body}"
        return {
          success: false,
          error: "Invalid response from payment gateway"
        }
      end
      
      Rails.logger.info "Checkout.com parsed response: #{response_data.inspect}"
      
      if response.code == '201' && response_data['approved']
        {
          success: true,
          payment_id: response_data['id'],
          response: response_data
        }
      else
        {
          success: false,
          error: response_data['response_summary'] || response_data['error_type'] || 'Payment failed',
          response: response_data
        }
      end
      
    rescue => e
      Rails.logger.error "Checkout.com API error: #{e.message}"
      {
        success: false,
        error: "Payment processing error: #{e.message}"
      }
    end
  end
end
