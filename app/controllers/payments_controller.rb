class PaymentsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_payment, only: [:show]
  layout 'user'
  
  def index
    @payments = current_user.payments.order(created_at: :desc)
                           .page(params[:page]).per(20)
    
    # Filter by status if provided
    if params[:status].present?
      @payments = @payments.where(status: params[:status])
    end
    
    # Filter by date range if provided
    if params[:start_date].present? && params[:end_date].present?
      @payments = @payments.where(created_at: params[:start_date]..params[:end_date])
    end
    
    # Calculate stats
    @stats = {
      total: current_user.payments.count,
      completed: current_user.payments.where(status: 'completed').count,
      pending: current_user.payments.where(status: 'pending').count,
      failed: current_user.payments.where(status: 'failed').count,
      total_amount: current_user.payments.where(status: 'completed').sum(:amount)
    }
  end
  
  def show
  end
  
  private
  
  def set_payment
    @payment = current_user.payments.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to payments_path, alert: "Payment not found."
  end
end
