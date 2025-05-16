module Admin
  class UsersController < ApplicationController
    before_action :authenticate_user!
    before_action :authenticate_admin!
    before_action :set_user, only: [:show, :edit, :update, :toggle_admin]

    def index
      @users = User.order(created_at: :desc).page(params[:page]).per(20)
      
      # Apply filters if provided
      if params[:email].present?
        @users = @users.where("email ILIKE ?", "%#{params[:email]}%")
      end
      
      if params[:admin].present?
        @users = @users.where(admin: params[:admin] == 'true')
      end
      
      # For CSV export
      respond_to do |format|
        format.html
        format.csv do
          send_data @users.to_csv,
            filename: "users-#{Date.today}.csv",
            type: "text/csv"
        end
      end
    end

    def show
      @trades = @user.trades.order(created_at: :desc).limit(10)
      @payments = @user.payments.order(created_at: :desc).limit(10)
      @user_channel_accesses = @user.user_channel_accesses.includes(:channel).order(access_end_date: :desc)
    end

    def edit
    end

    def update
      if @user.update(user_params)
        redirect_to admin_user_path(@user), notice: "User was successfully updated."
      else
        render :edit
      end
    end

    def toggle_admin
      @user.update(admin: !@user.admin)
      redirect_to admin_user_path(@user), notice: "Admin status toggled successfully."
    end

    private

    def set_user
      @user = User.find(params[:id])
    end

    def user_params
      params.require(:user).permit(:full_name, :email, :discord_id, :subscription_status, :admin)
    end

    def authenticate_admin!
      unless current_user&.admin?
        flash[:alert] = "You are not authorized to access this section."
        redirect_to root_path
      end
    end
  end
end
