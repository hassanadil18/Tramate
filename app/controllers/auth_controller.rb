class AuthController < ApplicationController
  # Skip any authentication requirements for these actions
  # Uncomment when authentication is implemented
  # skip_before_action :authenticate_user!, only: [:login, :register, :authenticate, :verify_discord_username, :get_channels]
  protect_from_forgery except: [ :verify_discord_username ]

  def login
    # Login page view
    # If already logged in, redirect to dashboard
  end

  def register
    # Registration page view
    # If already logged in, redirect to dashboard
    @user = User.new
    @channels = Channel.all
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

      # If this is an AJAX request, return JSON
      respond_to do |format|
        format.html { redirect_to dashboard_path, notice: "Account successfully created!" }
        format.json { render json: { success: true, user_id: @user.id } }
      end
    else
      # Show error and return errors for AJAX
      respond_to do |format|
        format.html { render :register }
        format.json { render json: { success: false, errors: @user.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  def logout
    # Clear session and redirect to home
    session[:user_id] = nil
    redirect_to root_path, notice: "You have been logged out."
  end

  # API endpoint to verify Discord username
  def verify_discord_username
    # Get parameters
    discord_username = params[:discord_username]
    channel_id = params[:channel_id]

    # This would be replaced by actual Discord API integration
    # Here we're simulating a check with a 70% success rate
    is_member = rand > 0.3

    if is_member
      render json: { success: true, message: "Username verified in channel!" }
    else
      channel = Channel.find_by(id: channel_id)
      invite_link = channel&.discord_invite_link || "https://discord.gg/tramate"
      render json: {
        success: false,
        message: "Username not found in channel.",
        invite_link: invite_link
      }
    end
  end

  # API endpoint to get all channels
  def get_channels
    channels = Channel.all.map { |c| { id: c.id, name: c.name, description: c.description } }
    render json: { channels: channels }
  end

  # API endpoint to update user with Discord and Binance info
  def update_connection_info
    user = User.find(params[:user_id])

    if user.update(connection_params)
      # Create API credential if Binance keys are provided
      if params[:binance_api_key].present? && params[:binance_api_secret].present?
        api_cred = user.api_credentials.new(
          provider: "binance",
          api_key: params[:binance_api_key],
          api_secret: params[:binance_api_secret],
          status: "active"
        )
        api_cred.save
      end

      render json: { success: true }
    else
      render json: { success: false, errors: user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.require(:user).permit(:email, :password, :password_confirmation, :full_name, :terms_of_service)
  end

  def connection_params
    params.permit(:discord_id, :binance_api_key, :binance_api_secret)
  end
end
