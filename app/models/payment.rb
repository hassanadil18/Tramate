class Payment < ApplicationRecord
  # Relationships
  belongs_to :user
  has_many :user_channel_accesses
  
  # Validations
  validates :amount, numericality: { greater_than: 0 }
  validates :status, presence: true, inclusion: { in: %w[pending processing completed failed refunded] }
  validates :payment_gateway_id, presence: true, uniqueness: true
  
  # Scopes
  scope :successful, -> { where(status: 'completed') }
  scope :pending, -> { where(status: 'pending') }
  scope :recent, -> { order(created_at: :desc) }
  
  # Callbacks
  before_save :update_status_timestamp
  
  # Class methods
  def self.to_csv
    require 'csv'
    
    CSV.generate(headers: true) do |csv|
      # Define headers
      csv << ['ID', 'User', 'Amount', 'Status', 'Payment Gateway ID', 'Date', 'Status Updated']
      
      # Add data rows
      all.includes(:user).each do |payment|
        csv << [
          payment.id,
          payment.user&.email || 'Unknown',
          payment.amount,
          payment.status.capitalize,
          payment.payment_gateway_id,
          payment.created_at.strftime("%Y-%m-%d"),
          payment.status_updated_at&.strftime("%Y-%m-%d %H:%M") || 'N/A'
        ]
      end
    end
  end
  
  private
  
  def update_status_timestamp
    self.status_updated_at = Time.current if status_changed?
  end
end