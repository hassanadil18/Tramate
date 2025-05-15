class User < ApplicationRecord
  has_secure_password

  # Relationships
  has_many :trades
  has_many :payments
  has_many :user_channel_accesses
  has_many :channels, through: :user_channel_accesses
  has_many :api_credentials, dependent: :destroy

  # Validations
  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :subscription_status, inclusion: { in: %w[active inactive pending] }, allow_nil: true
  validates :terms_of_service, acceptance: true

  # Virtual attribute for terms of service
  attr_accessor :terms_of_service

  # Encrypt the Binance API secret
  attr_encrypted :binance_api_secret, key: Rails.application.credentials.secret_key_base&.first(32) || 'x' * 32

  # Callbacks
  before_save :downcase_email

  # Method to check if user has valid Binance credentials
  def has_valid_binance_credentials?
    api_credentials.binance.active.exists?
  end

  private

  def downcase_email
    self.email = email.downcase if email.present?
  end
end
