class HealthController < ApplicationController
  skip_before_action :authenticate_user!
  
  def show
    health_status = {
      status: 'ok',
      timestamp: Time.current.iso8601,
      environment: Rails.env,
      version: '1.0.0',
      services: check_services
    }
    
    # Check if any critical services are down
    critical_services_down = health_status[:services].any? { |_, status| status[:status] == 'error' && status[:critical] }
    
    if critical_services_down
      health_status[:status] = 'error'
      render json: health_status, status: :service_unavailable
    else
      render json: health_status, status: :ok
    end
  end
  
  private
  
  def check_services
    services = {}
    
    # Database check
    services[:database] = check_database
    
    # Redis check (if configured)
    services[:redis] = check_redis if defined?(Redis)
    
    # Email service check
    services[:email] = check_email_service
    
    # External API checks
    services[:binance_api] = check_binance_api
    services[:discord_api] = check_discord_api
    
    services
  end
  
  def check_database
    ActiveRecord::Base.connection.execute('SELECT 1')
    {
      status: 'ok',
      critical: true,
      message: 'Database connection healthy',
      response_time: measure_response_time { ActiveRecord::Base.connection.execute('SELECT 1') }
    }
  rescue => e
    {
      status: 'error',
      critical: true,
      message: "Database connection failed: #{e.message}",
      response_time: nil
    }
  end
  
  def check_redis
    redis_url = ENV['REDIS_URL'] || Rails.application.credentials.redis&.url
    return { status: 'not_configured', critical: false, message: 'Redis not configured' } unless redis_url
    
    redis = Redis.new(url: redis_url)
    redis.ping
    {
      status: 'ok',
      critical: false,
      message: 'Redis connection healthy',
      response_time: measure_response_time { redis.ping }
    }
  rescue => e
    {
      status: 'error',
      critical: false,
      message: "Redis connection failed: #{e.message}",
      response_time: nil
    }
  end
  
  def check_email_service
    # Check if email configuration is present
    if ActionMailer::Base.smtp_settings.present? || ActionMailer::Base.delivery_method == :test
      {
        status: 'ok',
        critical: false,
        message: 'Email service configured',
        response_time: nil
      }
    else
      {
        status: 'warning',
        critical: false,
        message: 'Email service not configured',
        response_time: nil
      }
    end
  rescue => e
    {
      status: 'error',
      critical: false,
      message: "Email service check failed: #{e.message}",
      response_time: nil
    }
  end
  
  def check_binance_api
    # Simple connectivity check to Binance API
    response_time = measure_response_time do
      uri = URI('https://api.binance.com/api/v3/ping')
      Net::HTTP.get_response(uri)
    end
    
    {
      status: 'ok',
      critical: false,
      message: 'Binance API reachable',
      response_time: response_time
    }
  rescue => e
    {
      status: 'warning',
      critical: false,
      message: "Binance API unreachable: #{e.message}",
      response_time: nil
    }
  end
  
  def check_discord_api
    # Simple connectivity check to Discord API
    response_time = measure_response_time do
      uri = URI('https://discord.com/api/v10/gateway')
      Net::HTTP.get_response(uri)
    end
    
    {
      status: 'ok',
      critical: false,
      message: 'Discord API reachable',
      response_time: response_time
    }
  rescue => e
    {
      status: 'warning',
      critical: false,
      message: "Discord API unreachable: #{e.message}",
      response_time: nil
    }
  end
  
  def measure_response_time
    start_time = Time.current
    yield
    ((Time.current - start_time) * 1000).round(2) # Convert to milliseconds
  end
end
