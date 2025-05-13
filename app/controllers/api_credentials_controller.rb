class ApiCredentialsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_api_credential, only: [ :edit, :update, :destroy ]

  def index
    @api_credentials = current_user.api_credentials
  end

  def new
    @api_credential = current_user.api_credentials.new
  end

  def create
    @api_credential = current_user.api_credentials.new(api_credential_params)

    if @api_credential.verify_binance_credentials && @api_credential.save
      redirect_to api_credentials_path, notice: "Binance API connected successfully!"
    else
      flash.now[:alert] = "Failed to connect Binance API. Please check your credentials."
      render :new
    end
  end

  def edit
  end

  def update
    if @api_credential.update(api_credential_params)
      if params[:verify] == "true" && !@api_credential.verify_binance_credentials
        @api_credential.update(active: false)
        flash[:alert] = "API credentials updated but verification failed. Credentials marked as inactive."
      else
        flash[:notice] = "API credentials updated successfully."
      end
      redirect_to api_credentials_path
    else
      render :edit
    end
  end

  def destroy
    @api_credential.destroy
    redirect_to api_credentials_path, notice: "API credentials removed successfully."
  end

  private

  def set_api_credential
    @api_credential = current_user.api_credentials.find(params[:id])
  end

  def api_credential_params
    params.require(:api_credential).permit(:api_key, :api_secret, :platform, :label, :ip_restriction, :active)
  end
end
