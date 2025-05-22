class ApplicationController < ActionController::Base
  include Loggable

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  helper_method :current_user, :user_signed_in?

  protect_from_forgery with: :exception

  before_action :authenticate_user!

  protected

  def current_user
    @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id]
  end

  def user_signed_in?
    !!current_user
  end

  def authenticate_user!
    unless user_signed_in?
      flash[:alert] = "You need to login first"
      redirect_to auth_login_form_path
    end
  end

  def require_admin
    unless current_user&.admin?
      flash[:alert] = "You do not have permission to access this page"
      redirect_to dashboard_path
    end
  end

  def set_layout_for_role
    if current_user&.admin?
      'admin'
    else
      'user'
    end
  end
end
