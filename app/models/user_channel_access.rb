class UserChannelAccess < ApplicationRecord
  # Relationships
  belongs_to :user
  belongs_to :channel
  belongs_to :payment, optional: true
  
  # Validations
  validates :access_type, presence: true, inclusion: { in: %w[manual purchased] }
  validates :access_start_date, presence: true
  validates :access_end_date, presence: true
  validate :end_date_after_start_date
  
  # Scopes
  scope :active, -> { where('access_end_date > ?', Time.current) }
  scope :expired, -> { where('access_end_date <= ?', Time.current) }
  scope :purchased, -> { where(access_type: 'purchased') }
  scope :manual, -> { where(access_type: 'manual') }
  
  # Methods
  def active?
    access_end_date > Time.current
  end
  
  def days_remaining
    return 0 if expired?
    ((access_end_date - Time.current) / 1.day).to_i
  end
  
  def expired?
    access_end_date <= Time.current
  end
  
  private
  
  def end_date_after_start_date
    return if access_end_date.blank? || access_start_date.blank?
    
    if access_end_date <= access_start_date
      errors.add(:access_end_date, "must be after the start date")
    end
  end
end