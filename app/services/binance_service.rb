begin
  require 'binance'
rescue LoadError => e
  Rails.logger.error "Failed to load binance gem: #{e.message}"
  raise "Binance gem not available. Please ensure 'binance-connector-ruby' gem is installed."
end

# Official Binance Service using binance-connector-ruby gem
# Works with user-provided API credentials for individual customers
# Documentation: https://www.rubydoc.info/gems/binance-connector-ruby

class BinanceService
  attr_reader :client, :api_key, :api_secret, :testnet_mode
  
  # Initialize with user-provided API credentials
  def initialize(api_key = nil, api_secret = nil, testnet: false)
    @api_key = api_key&.strip
    @api_secret = api_secret&.strip
    @testnet_mode = testnet
    
    Rails.logger.info "BinanceService initialized for #{@testnet_mode ? 'TESTNET' : 'MAINNET'}"
    
    begin
      # Ensure Binance::Spot is available
      unless defined?(Binance::Spot)
        Rails.logger.error "Binance::Spot class not found. Available constants: #{Binance.constants.inspect}"
        raise "Binance::Spot class not available. Please restart the Rails server."
      end
      
      # Initialize Binance client using binance-connector-ruby gem
      client_options = {}
      
      # Set base URL for testnet if needed
      if @testnet_mode
        client_options[:base_url] = 'https://testnet.binance.vision'
      end
      
      # Add API credentials if provided
      if @api_key.present? && @api_secret.present?
        client_options[:key] = @api_key
        client_options[:secret] = @api_secret
        Rails.logger.info "Binance client initialized with user API credentials"
      else
        Rails.logger.info "Binance client initialized for public endpoints only"
      end
      
      # Set timeout and other options
      client_options[:timeout] = 10 # 10 second timeout
      client_options[:show_weight_usage] = true # Show rate limit usage
      
      @client = Binance::Spot.new(**client_options)
      Rails.logger.info "Binance::Spot client created successfully"
      
    rescue => e
      Rails.logger.error "Failed to initialize Binance client: #{e.message}"
      Rails.logger.error "Error class: #{e.class}"
      Rails.logger.error "Backtrace: #{e.backtrace.first(3).join(', ')}"
      @client = nil
    end
  end
  
  # Validate user-provided API keys
  def validate_api_keys
    return validation_error("API key and secret are required") if @api_key.blank? || @api_secret.blank?
    
    # Basic length validation
    return validation_error("API key is too short") if @api_key.length < 32
    return validation_error("API secret is too short") if @api_secret.length < 32
    
    return validation_error("Binance client not initialized") unless @client
    
    begin
      Rails.logger.info "Binance: Validating API credentials for user"
      
      # Test connectivity first
      Rails.logger.info "Binance: Testing connectivity..."
      unless test_connectivity
        return validation_error("Unable to connect to Binance API. Please check your internet connection.")
      end
      
      Rails.logger.info "Binance: Connectivity OK, testing API permissions..."
      
      # Test API key by getting account information
      account_data = @client.account
      
      Rails.logger.info "Binance: Account data retrieved successfully"
      
      {
        success: true,
        message: "API keys validated successfully!",
        account_type: account_data['accountType'] || 'SPOT',
        can_trade: account_data['canTrade'] || false,
        can_withdraw: account_data['canWithdraw'] || false,
        permissions: account_data['permissions'] || [],
        testnet: @testnet_mode
      }
      
    rescue Binance::ClientError => e
      Rails.logger.error "Binance Client Error: #{e.message}"
      handle_client_error(e)
    rescue Binance::ServerError => e
      Rails.logger.error "Binance Server Error: #{e.message}"
      validation_error("Binance server error. Please try again in a few moments.")
    rescue => e
      Rails.logger.error "Binance API validation error: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      validation_error("Connection error. Please check your internet connection and try again.")
    end
  end
  
  # Test connectivity using public endpoint
  def test_connectivity
    return false unless @client
    
    begin
      @client.time
      true
    rescue => e
      Rails.logger.error "Binance connectivity test failed: #{e.message}"
      false
    end
  end
  
  # Get account information (requires API key)
  def get_account_info
    return { success: false, error: "Binance client not initialized" } unless @client
    return { success: false, error: "API credentials required" } if @api_key.blank? || @api_secret.blank?
    
    begin
      account_data = @client.account
      {
        success: true,
        data: account_data
      }
    rescue Binance::ClientError => e
      Rails.logger.error "Binance account info error: #{e.message}"
      {
        success: false,
        error: parse_client_error(e)
      }
    rescue => e
      Rails.logger.error "Account info error: #{e.message}"
      {
        success: false,
        error: "Failed to get account information"
      }
    end
  end
  
  # Get symbol price (public endpoint)
  def get_symbol_price(symbol)
    return { success: false, error: "Client not initialized" } unless @client
    
    begin
      response = @client.ticker_24hr(symbol: symbol.upcase)
      {
        success: true,
        price: response['lastPrice'].to_f,
        symbol: response['symbol']
      }
    rescue Binance::ClientError => e
      {
        success: false,
        error: parse_client_error(e)
      }
    rescue => e
      {
        success: false,
        error: "Failed to get price for #{symbol}"
      }
    end
  end
  
  # Create a new order (requires API key)
  def create_order(params)
    return { success: false, error: "Client not initialized" } unless @client
    return { success: false, error: "API credentials required" } if @api_key.blank? || @api_secret.blank?
    
    begin
      # Validate required parameters
      validate_order_params(params)
      
      # Prepare order parameters
      order_params = {
        symbol: params[:symbol].upcase,
        side: params[:side].upcase,
        type: params[:type].upcase
      }
      
      # Add quantity and price based on order type
      case params[:type].upcase
      when 'MARKET'
        if params[:quote_order_qty]
          order_params[:quoteOrderQty] = params[:quote_order_qty]
        else
          order_params[:quantity] = params[:quantity]
        end
      when 'LIMIT'
        order_params[:quantity] = params[:quantity]
        order_params[:price] = params[:price]
        order_params[:timeInForce] = params[:time_in_force] || 'GTC'
      end
      
      # Add optional parameters
      order_params[:newClientOrderId] = params[:client_order_id] if params[:client_order_id]
      
      Rails.logger.info "Creating order: #{order_params}"
      
      # Create the order
      response = @client.new_order(**order_params)
      
      Rails.logger.info "Order created successfully: #{response['orderId']}"
      
      {
        success: true,
        data: response,
        order_id: response['orderId']
      }
      
    rescue Binance::ClientError => e
      Rails.logger.error "Order creation failed: #{e.message}"
      {
        success: false,
        error: parse_client_error(e)
      }
    rescue => e
      Rails.logger.error "Order creation error: #{e.message}"
      {
        success: false,
        error: "Failed to create order"
      }
    end
  end
  
  # Get open orders
  def get_open_orders(symbol = nil)
    return { success: false, error: "Client not initialized" } unless @client
    return { success: false, error: "API credentials required" } if @api_key.blank? || @api_secret.blank?
    
    begin
      params = {}
      params[:symbol] = symbol.upcase if symbol
      
      response = @client.open_orders(**params)
      
      {
        success: true,
        data: response,
        count: response.length
      }
    rescue Binance::ClientError => e
      {
        success: false,
        error: parse_client_error(e)
      }
    rescue => e
      {
        success: false,
        error: "Failed to get open orders"
      }
    end
  end
  
  private
  
  def validation_error(message)
    { success: false, message: message }
  end
  
  def validate_order_params(params)
    required_fields = [:symbol, :side, :type]
    
    required_fields.each do |field|
      raise ArgumentError, "#{field} is required" if params[field].blank?
    end
    
    # Validate order type specific requirements
    case params[:type].upcase
    when 'MARKET'
      unless params[:quantity] || params[:quote_order_qty]
        raise ArgumentError, "Either quantity or quote_order_qty is required for MARKET orders"
      end
    when 'LIMIT'
      if params[:quantity].blank? || params[:price].blank?
        raise ArgumentError, "Both quantity and price are required for LIMIT orders"
      end
    end
  end
  
  def handle_client_error(error)
    # Parse the error response from Binance
    error_code = error.response.dig(:body, 'code') if error.response
    error_msg = error.response.dig(:body, 'msg') if error.response
    
    case error_code
    when -2014
      validation_error("Invalid API key format.")
    when -1022
      validation_error("Invalid API secret or signature.")
    when -2015
      validation_error("Invalid API key, IP, or permissions for action.")
    when -1021
      validation_error("Timestamp issue. Please synchronize your system clock.")
    when -2010
      validation_error("Insufficient balance.")
    else
      # Use the message from Binance if available, otherwise use a generic message
      message = error_msg || parse_client_error(error)
      validation_error(message)
    end
  end
  
  def parse_client_error(error)
    # Extract error message from binance-connector-ruby ClientError
    if error.response && error.response[:body]
      error_data = error.response[:body]
      if error_data.is_a?(Hash)
        return error_data['msg'] || error_data['message'] || "API error"
      elsif error_data.is_a?(String)
        return error_data
      end
    end
    
    # Fallback to the exception message
    error.message || "Unknown API error"
  end
end 