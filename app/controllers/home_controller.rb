class HomeController < ApplicationController
  # This controller handles the landing page for the application.
  # It is responsible for rendering the home page and redirecting users
  # to the dashboard if they are already signed in.

  # Skip authentication for the home page
  skip_before_action :authenticate_user!, only: [:index]

  # Public landing page controller
  def index
    if user_signed_in?
      if current_user.admin?
        redirect_to admin_root_path
      else
        redirect_to dashboard_path
      end
    end
  end
end
