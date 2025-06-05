class Notification < ApplicationRecord
  belongs_to :user
  
  # Validations
  validates :message, presence: true
  
  # Scopes
  scope :unread, -> { where(read: false) }
  scope :read, -> { where(read: true) }
  scope :recent, -> { order(created_at: :desc) }
  scope :by_type, ->(type) { where(notification_type: type) if type.present? }
  
  # Types of notifications
  TYPES = {
    system: 'system',
    payment: 'payment',
    user: 'user',
    channel: 'channel',
    trade: 'trade'
  }
  
  # Mark notification as read
  def mark_as_read!
    update(read: true, read_at: Time.current)
  end
  
  # Parse the data JSON
  def parsed_data
    return {} if data.blank?
    data
  end
  
  # Class method to create a notification
  def self.notify(user, message, type = TYPES[:system], data = {})
    create(
      user: user,
      message: message,
      notification_type: type,
      data: data
    )
  end
end
