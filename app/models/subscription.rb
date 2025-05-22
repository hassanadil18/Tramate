class Subscription < ApplicationRecord
  belongs_to :user, optional: true
  
  # Validations
  validates :name, presence: true
  validates :price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :trade_limit, numericality: { only_integer: true }, allow_nil: true
  validates :status, inclusion: { in: %w[active canceled expired] }, allow_nil: true
  
  # Scopes
  scope :active, -> { where(status: 'active') }
  scope :available_plans, -> { where(user_id: nil) }
  
  # Class methods to access standard plans
  def self.starter
    available_plans.find_by(name: 'Starter')
  end
  
  def self.intermediate
    available_plans.find_by(name: 'Intermediate')
  end
  
  def self.premium
    available_plans.find_by(name: 'Premium')
  end
  
  # Create the standard subscription plans if they don't exist
  def self.create_default_plans
    # Starter plan (free)
    create_with(
      price: 0,
      description: 'Start with basic trading, limited to 1 trade per day',
      trade_limit: 1
    ).find_or_create_by!(name: 'Starter')
    
    # Intermediate plan ($5)
    create_with(
      price: 5.00,
      description: 'Step up your trading with up to 20 trades',
      trade_limit: 20
    ).find_or_create_by!(name: 'Intermediate')
    
    # Premium plan ($15)
    create_with(
      price: 15.00,
      description: 'Unlimited trading for serious traders',
      trade_limit: nil # nil means unlimited
    ).find_or_create_by!(name: 'Premium')
  end
  
  # Helper method to check if a subscription has unlimited trades
  def unlimited_trades?
    trade_limit.nil?
  end
end
