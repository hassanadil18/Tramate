class User < ApplicationRecord
  has_secure_password

  # Relationships
  has_many :trades, dependent: :destroy
  has_many :payments, dependent: :destroy
  has_many :user_channel_accesses
  has_many :channels, through: :user_channel_accesses, dependent: :destroy
  has_many :api_credentials, dependent: :destroy
  has_many :notifications, dependent: :destroy
  belongs_to :subscription, optional: true

  # Validations
  validates :email, presence: true, uniqueness: { case_sensitive: false }, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :full_name, presence: true
  validates :discord_username, presence: true, allow_nil: true
  validates :subscription_status, inclusion: { in: %w[active inactive pending] }, allow_nil: true
  validates :terms_of_service, acceptance: true
  validates :password, length: { minimum: 6 }, allow_nil: true

  # Virtual attributes
  attr_accessor :terms_of_service, :discord_username, :password_confirmation, :first_name, :last_name

  # First name accessor methods
  def first_name
    @first_name ||= full_name&.split(' ', 2)&.first
  end
  
  def first_name=(value)
    @first_name = value
    update_full_name
  end
  
  # Last name accessor methods 
  def last_name
    @last_name ||= full_name&.split(' ', 2)&.last
  end
  
  def last_name=(value)
    @last_name = value
    update_full_name
  end
  
  # Update full_name when first_name or last_name changes
  def update_full_name
    if @first_name.present? || @last_name.present?
      self.full_name = [@first_name, @last_name].compact.join(' ')
    end
  end

  # Encrypt the Binance API secret
  attr_encrypted :binance_api_secret, key: Rails.application.credentials.secret_key_base&.first(32) || "x" * 32

  # Callbacks
  before_save :downcase_email
  before_create :set_default_subscription
  
  # Class methods
  def self.to_csv
    require 'csv'
    
    CSV.generate(headers: true) do |csv|
      # Define headers
      csv << ['ID', 'Name', 'Email', 'Discord ID', 'Admin Status', 'Subscription Status', 'Registration Date']
      
      # Add data rows
      all.each do |user|
        csv << [
          user.id,
          user.full_name,
          user.email,
          user.discord_id || '-',
          user.admin? ? 'Admin' : 'User',
          user.subscription_status&.capitalize || 'Inactive',
          user.created_at.strftime("%Y-%m-%d")
        ]
      end
    end
  end

  # Method to check if user has valid Binance credentials
  def has_valid_binance_credentials?
    api_credentials.exists?(platform: 'binance', active: true)
  end
  
  # Subscription-related methods
  def active_subscription?
    subscription_status == 'active' && 
      (subscription_end_date.nil? || subscription_end_date > Time.current)
  end
  
  def can_make_trade?
    return true if subscription&.unlimited_trades?
    return true if subscription&.trade_limit.to_i > trades_count.to_i
    false
  end
  
  def trades_remaining
    return Float::INFINITY if subscription&.unlimited_trades?
    
    if subscription
      # Calculate remaining trades from subscription limits
      total_used = trades.where('created_at >= ?', subscription_start_date).count
      [0, subscription.trade_limit - total_used].max
    else
      # Free tier: 1 trade per day
      daily_trades_used = trades.where('created_at >= ?', Time.current.beginning_of_day).count
      [0, 1 - daily_trades_used].max
    end
  end
  
  def can_execute_trade?
    trades_remaining > 0
  end
  
  def subscription_start_date
    created_at # Default to user creation date unless otherwise recorded
  end
  
  def record_trade
    return false unless can_make_trade?
    
    increment!(:trades_count)
    true
  end
  
  def reset_trades_count
    update(trades_count: 0)
  end
  
  # Admin methods
  def admin?
    admin
  end

  private

  def downcase_email
    self.email = email.downcase if email.present?
  end
  
  def set_default_subscription
    # If no subscription is set, assign the free plan by default
    if subscription.nil?
      self.subscription = Subscription.starter
      self.subscription_status = 'active'
      self.trades_count = 0
    end
  end
end
