class AuthController < ApplicationController
  # Skip any authentication requirements for these actions
  # Uncomment when authentication is implemented
  # skip_before_action :authenticate_user!, only: [:login, :register, :authenticate]

  def login
    # Login page view
    # If already logged in, redirect to dashboard
  end

  def register
    # Registration page view
    # If already logged in, redirect to dashboard
    @user = User.new
  end

  def authenticate
    # Process login form submission
    email = params[:email]
    password = params[:password]

    user = User.find_by(email: email.downcase)

    if user && user.authenticate(password)
      # Set session and redirect to dashboard
      session[:user_id] = user.id
      redirect_to dashboard_path, notice: "Successfully logged in!"
    else
      # Show error and redirect back to login
      flash.now[:alert] = "Invalid email or password"
      render :login
    end
  end

  def create
    # Process registration form submission
    @user = User.new(user_params)

    if @user.save
      # Set session and redirect to dashboard
      session[:user_id] = @user.id
      redirect_to dashboard_path, notice: "Account successfully created!"
    else
      # Show error and redirect back to registration form
      render :register
    end
  end

  def logout
    # Clear session and redirect to home
    session[:user_id] = nil
    redirect_to root_path, notice: "You have been logged out."
  end

  private

  def user_params
    params.require(:user).permit(:email, :password, :password_confirmation, :terms_of_service)
  end
end
