require 'net/http'
require 'uri'
require 'json'
require 'openssl'
require 'timeout'

class BinanceService
  BASE_URL = 'https://api.binance.com'
  REQUEST_TIMEOUT = 10 # seconds
  
  def initialize(api_key = nil, api_secret = nil)
    @api_key = api_key&.strip
    @api_secret = api_secret&.strip
  end
  
  # Validate API keys by testing account access
  def validate_api_keys
    return { success: false, message: "API key and secret are required" } if @api_key.blank? || @api_secret.blank?
    
    # Basic format validation
    return { success: false, message: "API key must be 64 characters long" } if @api_key.length != 64
    return { success: false, message: "API secret must be 64 characters long" } if @api_secret.length != 64
    
    begin
      # Test connectivity first
      unless self.class.test_connectivity
        return { success: false, message: "Unable to connect to Binance API. Please check your internet connection." }
      end
      
      # Test with account info endpoint (requires signature)
      response = get_account_info
      
      if response['code']
        # API returned an error
        case response['code']
        when -2014
          { success: false, message: "API key format is invalid" }
        when -1021
          { success: false, message: "Timestamp outside of receive window. Please check your system clock." }
        when -1022
          { success: false, message: "Invalid signature - please check your API secret" }
        when -2015
          { success: false, message: "Invalid API key, IP restriction, or insufficient permissions" }
        when -1003
          { success: false, message: "Too many requests. Please wait a moment and try again." }
        else
          { success: false, message: "API validation failed: #{response['msg']}" }
        end
      elsif response['accountType']
        # Success - we got account info
        { 
          success: true, 
          message: "API keys validated successfully!",
          account_type: response['accountType'],
          can_trade: response['canTrade'],
          can_withdraw: response['canWithdraw']
        }
      else
        { success: false, message: "Unexpected response from Binance API" }
      end
      
    rescue Timeout::Error
      { success: false, message: "Request timed out. Please try again." }
    rescue SocketError, Errno::ECONNREFUSED
      { success: false, message: "Network connection failed. Please check your internet connection." }
    rescue => e
      Rails.logger.error "Binance API validation error: #{e.message}"
      { success: false, message: "Unable to validate API keys. Please try again." }
    end
  end
  
  # Test API connectivity (no auth required)
  def self.test_connectivity
    begin
      uri = URI("#{BASE_URL}/api/v3/ping")
      response = Net::HTTP.get_response(uri)
      response.code == '200'
    rescue => e
      Rails.logger.error "Binance connectivity test failed: #{e.message}"
      false
    end
  end
  
  # Get server time (no auth required)
  def self.get_server_time
    begin
      uri = URI("#{BASE_URL}/api/v3/time")
      response = Net::HTTP.get_response(uri)
      JSON.parse(response.body)['serverTime']
    rescue => e
      Rails.logger.error "Failed to get Binance server time: #{e.message}"
      Time.current.to_i * 1000
    end
  end
  
  private
  
  # Get account information (requires signature)
  def get_account_info
    timestamp = self.class.get_server_time
    query_string = "timestamp=#{timestamp}"
    signature = generate_signature(query_string)
    
    uri = URI("#{BASE_URL}/api/v3/account?#{query_string}&signature=#{signature}")
    
    Timeout::timeout(REQUEST_TIMEOUT) do
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_PEER
      http.read_timeout = REQUEST_TIMEOUT
      http.open_timeout = REQUEST_TIMEOUT
      
      request = Net::HTTP::Get.new(uri)
      request['X-MBX-APIKEY'] = @api_key
      
      response = http.request(request)
      JSON.parse(response.body)
    end
  end
  
  # Generate HMAC SHA256 signature for Binance API
  def generate_signature(query_string)
    OpenSSL::HMAC.hexdigest('sha256', @api_secret, query_string)
  end
end 