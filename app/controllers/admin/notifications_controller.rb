class Admin::NotificationsController < Admin::BaseController
  before_action :set_notification, only: [:mark_as_read]
  
  def index
    @notifications = current_user.notifications.recent.limit(50)
  end
  
  def fetch
    @notifications = current_user.notifications.unread.recent.limit(10)
    render json: {
      notifications: @notifications.map { |n| notification_json(n) },
      unread_count: current_user.notifications.unread.count
    }
  end

  def mark_as_read
    @notification.mark_as_read!
    respond_to do |format|
      format.html { redirect_to admin_notifications_path, notice: 'Notification marked as read.' }
      format.json { render json: { success: true } }
    end
  end
  
  def mark_all_as_read
    current_user.notifications.unread.update_all(read: true, read_at: Time.current)
    respond_to do |format|
      format.html { redirect_to admin_notifications_path, notice: 'All notifications marked as read.' }
      format.json { render json: { success: true } }
    end
  end
  
  private
  
  def set_notification
    @notification = current_user.notifications.find(params[:id])
  end
  
  def notification_json(notification)
    {
      id: notification.id,
      message: notification.message,
      notification_type: notification.notification_type,
      read: notification.read,
      created_at: notification.created_at.strftime("%b %d, %Y at %I:%M %p"),
      data: notification.parsed_data
    }
  end
end
