class Trade < ApplicationRecord
  # Relationships
  belongs_to :user
  belongs_to :trade_signal, optional: true, foreign_key: 'trade_signal_id'

  # Modern JSON attributes
  attribute :pre_trade_data, :json
  attribute :post_trade_data, :json
  attribute :error_data, :json
  attribute :take_profit_data, :json
  attribute :stop_loss_data, :json


  # Validations
  validates :user_id, presence: true
  validates :status, presence: true, inclusion: { in: ['pending', 'completed', 'failed', 'cancelled'] }
  validates :coin, presence: true
  validates :amount, numericality: { greater_than: 0 }, allow_nil: true

  # Scopes
  scope :completed, -> { where(status: "completed") }
  scope :executed, -> { where(status: "executed") }
  scope :pending, -> { where(status: "pending") }
  scope :failed, -> { where(status: "failed") }
  scope :skipped, -> { where(status: "skipped") }
  scope :recent, -> { order(created_at: :desc) }
  scope :this_week, -> { where("created_at > ?", 1.week.ago) }
  scope :by_coin, ->(coin) { where(coin: coin) }

  # Callbacks
  before_create :set_timestamp
  
  # Class methods for export
  def self.to_csv
    require 'csv'
    
    CSV.generate(headers: true) do |csv|
      # Define headers
      csv << [
        'ID', 'User', 'Status', 'Coin', 'Amount', 
        'Signal ID', 'Execution Price', 'Created At'
      ]
      
      # Add data rows
      all.includes(:user).each do |trade|
        csv << [
          trade.id,
          trade.user&.email || 'Unknown',
          trade.status.capitalize,
          trade.coin,
          trade.amount,
          trade.trade_signal_id,
          trade.execution_price,
          trade.created_at.strftime("%Y-%m-%d %H:%M")
        ]
      end
    end
  end

  # Returns trades with issues that admin should review
  def self.needs_review
    where("status = 'failed' OR (status = 'executed' AND notes LIKE '%error%')")
  end

  # Calculate profit/loss of completed trade
  def profit_loss
    return nil unless status == "completed" && execution_price.present? && exit_price.present?

    pl = if order_side == "BUY"
      ((exit_price - execution_price) / execution_price) * 100
    else
      ((execution_price - exit_price) / execution_price) * 100
    end

    pl.round(2)
  end

  # Determine if trade executed correctly compared to signal
  def matches_signal?
    return false unless trade_signal && trade_signal.parsed_data.present?

    # Check if the coin, price range matches what we expected
    correct_coin = coin.to_s.downcase == trade_signal.parsed_data[:coin].to_s.downcase
    price_within_range = execution_price &&
                        (execution_price >= trade_signal.parsed_data[:entry_price].to_f * 0.98) &&
                        (execution_price <= trade_signal.parsed_data[:entry_price].to_f * 1.02)

    correct_coin && price_within_range
  end

  # For admin to manually mark a trade for review
  def flag_for_review(reason)
    update(
      needs_review: true,
      review_reason: reason,
      review_requested_at: Time.current
    )
  end

  # Methods
  def successful?
    status == 'completed'
  end
  
  def failed?
    status == 'failed'
  end
  
  def pending?
    status == 'pending'
  end

  private

  def set_timestamp
    self.timestamp ||= Time.current
  end
end
