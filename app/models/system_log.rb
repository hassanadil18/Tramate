class SystemLog < ApplicationRecord
  # Validations
  validates :level, presence: true, inclusion: { in: ['info', 'warn', 'error', 'debug'] }
  validates :message, presence: true
  
  # Scopes
  scope :recent, -> { order(created_at: :desc) }
  scope :errors, -> { where(level: 'error') }
  scope :warnings, -> { where(level: 'warn') }
  scope :info, -> { where(level: 'info') }

  # Class methods for logging
  def self.log_info(message, source = nil, context = nil)
    create(level: 'info', message: message, source: source, context: context)
  end

  def self.log_warning(message, source = nil, context = nil)
    create(level: 'warn', message: message, source: source, context: context)
  end

  def self.log_error(message, source = nil, context = nil)
    create(level: 'error', message: message, source: source, context: context)
  end

  def self.log_debug(message, source = nil, context = nil)
    return unless Rails.env.development? || Rails.env.test?
    create(level: 'debug', message: message, source: source, context: context)
  end

  # Check if this is an error log
  def error?
    level == 'error'
  end

  # Check if this is a warning log
  def warning?
    level == 'warn'
  end

  # Instance methods
  def context_data
    return {} if context.blank?
    JSON.parse(context)
  rescue JSON::ParserError
    { raw: context }
  end
end 