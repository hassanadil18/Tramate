module Loggable
  extend ActiveSupport::Concern

  included do
    after_action :log_request
  end

  private

  def log_request
    return if request.path.start_with?('/assets/', '/packs/')
    
    context = {
      controller: controller_name,
      action: action_name,
      params: filtered_params,
      user_id: current_user&.id,
      ip: request.remote_ip,
      user_agent: request.user_agent
    }
    
    if response.status >= 500
      SystemLog.log_error("Server Error: #{response.status}", context)
    elsif response.status >= 400
      SystemLog.log_warning("Client Error: #{response.status}", context)
    else
      SystemLog.log_info("Request completed: #{request.method} #{request.path}", context)
    end
  end

  def filtered_params
    params.except(:controller, :action, :password, :password_confirmation, :token)
  end
end 