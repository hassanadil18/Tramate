class ApiCredential < ApplicationRecord
  belongs_to :user

  # Encrypt sensitive data
  encrypts :api_key
  encrypts :api_secret

  # Validations
  validates :api_key, presence: true
  validates :api_secret, presence: true
  validates :platform, presence: true, inclusion: { in: [ "binance" ] }
  validates :label, presence: true

  # Scopes
  scope :active, -> { where(active: true) }
  scope :binance, -> { where(platform: "binance") }

  # Default values
  attribute :active, :boolean, default: true

  # Verify Binance API credentials work
  def verify_binance_credentials
    begin
      client = Binance::ApiClient.new(api_key: api_key, api_secret: api_secret)
      account_info = client.account_info
      account_info.present?
    rescue => e
      errors.add(:base, "Invalid Binance credentials: #{e.message}")
      false
    end
  end
end
