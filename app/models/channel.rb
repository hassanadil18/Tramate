class Channel < ApplicationRecord
  # Relationships
  has_many :trade_signals
  has_many :user_channel_accesses
  has_many :users, through: :user_channel_accesses

  # Validations
  validates :name, presence: true
  validates :price_per_month, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :discord_channel_id, presence: true, uniqueness: true
  validates :tramate_resell_enabled, inclusion: { in: [true, false] }
  validates :status, inclusion: { in: ['active', 'inactive'] }, allow_nil: true
  validates :channel_type, inclusion: { in: ['telegram', 'discord', 'webhook'] }, allow_nil: true
  
  # Set default values
  after_initialize :set_defaults, if: :new_record?

  # Scopes
  scope :resellable, -> { where(tramate_resell_enabled: true) }
  scope :active, -> { where(status: 'active') }
  scope :inactive, -> { where(status: 'inactive') }
  
  # Class methods
  def self.to_csv
    require 'csv'
    
    CSV.generate(headers: true) do |csv|
      # Define headers
      csv << ['ID', 'Name', 'Type', 'Status', 'Discord Channel ID', 'Price', 'Description', 'Subscribers', 'Signals']
      
      # Add data rows
      all.includes(:user_channel_accesses, :trade_signals).each do |channel|
        csv << [
          channel.id,
          channel.name,
          channel.channel_type&.titleize || 'Discord',
          channel.status&.titleize || 'Active',
          channel.discord_channel_id,
          channel.price_per_month,
          channel.description,
          channel.user_channel_accesses.count,
          channel.trade_signals.count
        ]
      end
    end
  end
  
  private
  
  def set_defaults
    self.status ||= 'active'
    self.channel_type ||= 'discord'
  end
end