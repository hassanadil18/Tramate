require "httparty"
require "openssl"
require "json"

module Binance
  class ApiClient
    include HTTParty
    base_uri "https://api.binance.com"

    attr_reader :api_key, :api_secret

    def initialize(api_key:, api_secret:)
      @api_key = api_key
      @api_secret = api_secret
      @base_url = ENV.fetch("BINANCE_API_BASE_URL", "https://api.binance.com")
    end

    # Verify API connection b& rails generate migration AddTrackingFieldsToTrades pre_trade_data:json post_trade_data:json error_data:json y getting account info
    def account_info
      request("/api/v3/account", :get)
    end

    # Get current price for a symbol
    def price(symbol:)
      response = self.class.get("/api/v3/ticker/price", query: { symbol: symbol })

      if response.success?
        response.parsed_response["price"]
      else
        raise "Failed to get price: #{response.code} - #{response.body}"
      end
    end

    # Create a new order
    def create_order(symbol:, side:, type:, quantity:, price: nil, stop_price: nil, time_in_force: "GTC")
      params = {
        symbol: symbol,
        side: side,
        type: type,
        quantity: quantity,
        timeInForce: time_in_force
      }

      params[:price] = price if price
      params[:stopPrice] = stop_price if stop_price

      request("/api/v3/order", :post, params)
    end

    # Get order status
    def order_status(symbol:, order_id:)
      request("/api/v3/order", :get, { symbol: symbol, orderId: order_id })
    end

    # Cancel an order
    def cancel_order(symbol:, order_id:)
      request("/api/v3/order", :delete, { symbol: symbol, orderId: order_id })
    end

    private

    def request(endpoint, method, params = {})
      params[:timestamp] = (Time.now.to_f * 1000).to_i
      params[:recvWindow] = 5000 # Optional, adjust as needed

      query = URI.encode_www_form(params)
      signature = OpenSSL::HMAC.hexdigest("sha256", api_secret, query)
      query_with_signature = "#{query}&signature=#{signature}"

      headers = { "X-MBX-APIKEY" => api_key }

      response = case method
      when :get
                   self.class.get("#{endpoint}?#{query_with_signature}", headers: headers)
      when :post
                   self.class.post("#{endpoint}?#{query_with_signature}", headers: headers)
      when :delete
                   self.class.delete("#{endpoint}?#{query_with_signature}", headers: headers)
      end

      if response.success?
        response.parsed_response
      else
        error_message = begin
                          JSON.parse(response.body)["msg"] || response.body
                        rescue
                          response.body
                        end
        raise "Binance API error (#{response.code}): #{error_message}"
      end
    end
  end
end
