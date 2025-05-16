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
    current_user.present?
  end

  def authenticate_user!
    unless current_user
      flash[:alert] = "Please log in to continue."
      redirect_to auth_login_path
    end
  end
end
