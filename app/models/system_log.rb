class SystemLog < ApplicationRecord
  # Validations
  validates :level, presence: true, inclusion: { in: %w[error warning info debug] }
  validates :message, presence: true
  
  # Scopes
  scope :error, -> { where(level: 'error') }
  scope :warning, -> { where(level: 'warning') }
  scope :info, -> { where(level: 'info') }
  scope :debug, -> { where(level: 'debug') }
  
  # Class methods for logging
  def self.log_error(message, context = nil)
    create(level: 'error', message: message, context: context)
  end
  
  def self.log_warning(message, context = nil)
    create(level: 'warning', message: message, context: context)
  end
  
  def self.log_info(message, context = nil)
    create(level: 'info', message: message, context: context)
  end
  
  def self.log_debug(message, context = nil)
    create(level: 'debug', message: message, context: context)
  end
  
  # Instance methods
  def context_data
    return {} if context.blank?
    JSON.parse(context)
  rescue JSON::ParserError
    { raw: context }
  end
end 