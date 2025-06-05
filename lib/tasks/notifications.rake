namespace :notifications do
  desc "Create test notifications for admin users"
  task create_test: :environment do
    # Find admin users
    admin_users = User.where(admin: true)

    if admin_users.any?
      admin_users.each do |user|
        # Create system notifications
        Notification.create!(
          user: user,
          message: "Welcome to Tramate Admin Dashboard!",
          notification_type: Notification::TYPES[:system],
          read: false,
          data: { welcome: true }
        )
        
        Notification.create!(
          user: user,
          message: "New user registration: John Doe",
          notification_type: Notification::TYPES[:user],
          read: false,
          data: { user_id: 1 }
        )
        
        Notification.create!(
          user: user,
          message: "New payment received: $99.99",
          notification_type: Notification::TYPES[:payment],
          read: false,
          data: { payment_id: 1, amount: 99.99 }
        )
        
        Notification.create!(
          user: user,
          message: "New channel created: Crypto Signals",
          notification_type: Notification::TYPES[:channel],
          read: false,
          data: { channel_id: 1 }
        )
        
        Notification.create!(
          user: user,
          message: "System update scheduled for tomorrow",
          notification_type: Notification::TYPES[:system],
          read: false,
          data: { maintenance: true, scheduled_at: Time.current + 1.day }
        )
        
        puts "Created 5 notifications for #{user.email}"
      end
    else
      puts "No admin users found. Skipping notification creation."
    end

    puts "Notifications created successfully!"
  end
end 