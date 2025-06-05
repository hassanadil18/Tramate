# Binance API Configuration
# Official Binance Connector Ruby Gem Configuration

require 'binance'

# Configure Binance client for testnet/mainnet
Rails.application.configure do
  # Use testnet for development and testing
  config.binance_testnet = Rails.env.development? || Rails.env.test? || ENV['BINANCE_TESTNET'] == 'true'
  
  # Base URLs according to official documentation
  config.binance_spot_base_url = if config.binance_testnet
    'https://testnet.binance.vision'  # Testnet URL
  else
    'https://api.binance.com'         # Production URL
  end
  
  # Rate limiting configuration (as per Binance API limits)
  config.binance_rate_limits = {
    requests_per_minute: 1200,      # 1200 requests per minute
    orders_per_second: 10,          # 10 orders per second
    orders_per_day: 200_000         # 200,000 orders per 24hrs
  }
  
  # Default order parameters
  config.binance_defaults = {
    recv_window: 5000,              # 5 seconds receive window
    time_in_force: 'GTC',           # Good Till Cancelled
    test_orders_in_dev: true        # Use test orders in development
  }
end

# Set default logging for HTTP requests (optional)
if defined?(Faraday)
  # Configure Faraday logging if needed
  # This will be handled in the BinanceService class
end
