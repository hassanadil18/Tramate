module Admin
  class PaymentsController < BaseController
    before_action :set_payment, only: [:show, :update]

    def index
      @payments = Payment.includes(:user)
                         .order(created_at: :desc)
                         .page(params[:page]).per(20)
      
      # Apply filters if provided
      if params[:status].present?
        @payments = @payments.where(status: params[:status])
      end
      
      if params[:user_id].present?
        @payments = @payments.where(user_id: params[:user_id])
      end
      
      # For CSV export
      respond_to do |format|
        format.html
        format.csv do
          send_data @payments.to_csv,
            filename: "payments-#{Date.today}.csv",
            type: "text/csv"
        end
      end
    end

    def show
      @user = @payment.user
    end

    def update
      if @payment.update(payment_params)
        redirect_to admin_payment_path(@payment), notice: "Payment was successfully updated."
      else
        redirect_to admin_payment_path(@payment), alert: "Failed to update payment."
      end
    end

    private

    def set_payment
      @payment = Payment.find(params[:id])
    end

    def payment_params
      params.require(:payment).permit(:status, :notes)
    end
  end
end
