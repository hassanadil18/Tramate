class Trade < ApplicationRecord
  # Relationships
  belongs_to :user
  belongs_to :signal

  # Store JSON data for trade tracking
  serialize :pre_trade_data, JSON
  serialize :post_trade_data, JSON
  serialize :error_data, JSON
  serialize :take_profit_data, JSON
  serialize :stop_loss_data, JSON

  # Validations
  validates :status, presence: true, inclusion: { in: %w[pending executing executed completed failed canceled skipped] }
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
    return false unless signal && signal.parsed_data.present?

    # Check if the coin, price range matches what we expected
    correct_coin = coin.to_s.downcase == signal.parsed_data[:coin].to_s.downcase
    price_within_range = execution_price &&
                        (execution_price >= signal.parsed_data[:entry_price].to_f * 0.98) &&
                        (execution_price <= signal.parsed_data[:entry_price].to_f * 1.02)

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

  private

  def set_timestamp
    self.timestamp ||= Time.current
  end
end
