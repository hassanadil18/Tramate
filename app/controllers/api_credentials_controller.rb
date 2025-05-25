class ApiCredentialsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_api_credential, only: [:show, :edit, :update, :destroy, :validate]
  layout 'user'
  
  def index
    @api_credentials = current_user.api_credentials.order(created_at: :desc)
    @new_credential = ApiCredential.new
  end
  
  def show
  end
  
  def new
    @api_credential = current_user.api_credentials.build
  end
  
  def create
    @api_credential = current_user.api_credentials.build(api_credential_params)
    
    if @api_credential.save
      # Validate the API credentials if they're for Binance
      if @api_credential.platform == 'binance'
        begin
          binance_service = BinanceService.new(@api_credential.api_key, @api_credential.api_secret)
          validation_result = binance_service.validate_api_keys
          
          if validation_result[:success]
            @api_credential.update!(
              active: true,
              account_type: validation_result[:account_type],
              can_trade: validation_result[:can_trade],
              can_withdraw: validation_result[:can_withdraw],
              validated_at: Time.current
            )
            redirect_to api_credentials_path, notice: 'API credentials were successfully created and validated.'
          else
            @api_credential.update!(active: false)
            redirect_to api_credentials_path, alert: "API credentials created but validation failed: #{validation_result[:message]}"
          end
        rescue => e
          @api_credential.update!(active: false)
          redirect_to api_credentials_path, alert: "API credentials created but validation failed: #{e.message}"
        end
      else
        redirect_to api_credentials_path, notice: 'API credentials were successfully created.'
      end
    else
      @api_credentials = current_user.api_credentials.order(created_at: :desc)
      render :index
    end
  end
  
  def edit
  end
  
  def update
    if @api_credential.update(api_credential_params)
      # Re-validate if API keys changed
      if @api_credential.platform == 'binance' && (@api_credential.saved_change_to_api_key? || @api_credential.saved_change_to_api_secret?)
        begin
          binance_service = BinanceService.new(@api_credential.api_key, @api_credential.api_secret)
          validation_result = binance_service.validate_api_keys
          
          if validation_result[:success]
            @api_credential.update!(
              active: true,
              account_type: validation_result[:account_type],
              can_trade: validation_result[:can_trade],
              can_withdraw: validation_result[:can_withdraw],
              validated_at: Time.current
            )
            redirect_to api_credentials_path, notice: 'API credentials were successfully updated and validated.'
          else
            @api_credential.update!(active: false)
            redirect_to api_credentials_path, alert: "API credentials updated but validation failed: #{validation_result[:message]}"
          end
        rescue => e
          @api_credential.update!(active: false)
          redirect_to api_credentials_path, alert: "API credentials updated but validation failed: #{e.message}"
        end
      else
        redirect_to api_credentials_path, notice: 'API credentials were successfully updated.'
      end
    else
      render :edit
    end
  end
  
  def validate
    if @api_credential.platform == 'binance'
      begin
        binance_service = BinanceService.new(@api_credential.api_key, @api_credential.api_secret)
        validation_result = binance_service.validate_api_keys
        
        if validation_result[:success]
          @api_credential.update!(
            active: true,
            account_type: validation_result[:account_type],
            can_trade: validation_result[:can_trade],
            can_withdraw: validation_result[:can_withdraw],
            validated_at: Time.current
          )
          redirect_to api_credentials_path, notice: 'API credentials validated successfully!'
        else
          @api_credential.update!(active: false)
          redirect_to api_credentials_path, alert: "Validation failed: #{validation_result[:message]}"
        end
      rescue => e
        @api_credential.update!(active: false)
        redirect_to api_credentials_path, alert: "Validation failed: #{e.message}"
      end
    else
      redirect_to api_credentials_path, alert: "Validation is only available for Binance credentials."
    end
  end
  
  def destroy
    @api_credential.destroy
    redirect_to api_credentials_path, notice: 'API credentials were successfully deleted.'
  end
  
  private
  
  def set_api_credential
    @api_credential = current_user.api_credentials.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to api_credentials_path, alert: "API credential not found."
  end
  
  def api_credential_params
    params.require(:api_credential).permit(:platform, :api_key, :api_secret, :label, :active)
  end
end 