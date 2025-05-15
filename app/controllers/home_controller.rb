class HomeController < ApplicationController
  # This controller handles the landing page for the application.
  # It is responsible for rendering the home page and redirecting users
  # to the dashboard if they are already signed in.

  # Public landing page controller
  def index
    # Landing page for visitors
    # Only redirect if the user is signed in
    redirect_to dashboard_path if user_signed_in? rescue nil
  end
end
