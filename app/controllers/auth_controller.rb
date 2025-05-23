class AuthController < ApplicationController
  # Skip any authentication requirements for these actions
  # Uncomment when authentication is implemented
  skip_before_action :authenticate_user!, except: [:logout]
  protect_from_forgery except: [ :verify_discord_username ]
  layout 'auth'

  def login_form
    redirect_to dashboard_path if user_signed_in?
    render :login
  end

  def register_form
    redirect_to dashboard_path if user_signed_in?
    @user = User.new
    render :register
  end

  def login
    user = User.find_by(email: params[:email])
    
    if user && user.authenticate(params[:password])
      session[:user_id] = user.id
      redirect_to dashboard_path, notice: "Successfully logged in!"
      # Send login notification email
      UserMailer.login_notification(user).deliver_later
    else
      # Show error and redirect back to login
      flash.now[:alert] = "Invalid email or password"
      render :login
    end
  end

  def register
    @user = User.new(user_params)
    
    if @user.save
      session[:user_id] = @user.id

      # If this is an AJAX request, return JSON
      # Send signup notification email
      UserMailer.signup_notification(@user).deliver_later
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
          platform: "binance",
          api_key: params[:binance_api_key],
          api_secret: params[:binance_api_secret],
          label: "Binance API",
          active: true
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
    # If first_name and last_name are provided, combine them into full_name
    if params[:user][:first_name].present? && params[:user][:last_name].present?
      params[:user][:full_name] = "#{params[:user][:first_name]} #{params[:user][:last_name]}"
    end
    
    params.require(:user).permit(:full_name, :email, :password, :password_confirmation, :terms_of_service)
  end

  def connection_params
    params.permit(:discord_id, :binance_api_key, :binance_api_secret)
  end
end
