#!/usr/bin/env ruby

# Rails Credentials Test Script
# Tests if Rails credentials are properly configured for email

require_relative '../config/environment'

class RailsCredentialsTest
  def self.run
    puts "🔐 RAILS CREDENTIALS EMAIL TEST"
    puts "=" * 50
    puts
    
    # Test credentials loading
    test_credentials_loading
    
    # Test email configuration
    test_email_configuration
    
    # Test email sending with credentials
    test_email_with_credentials
    
    puts "\n✅ RAILS CREDENTIALS TEST COMPLETED!"
    puts "=" * 50
  end
  
  private
  
  def self.test_credentials_loading
    puts "🔑 Testing Credentials Loading..."
    
    begin
      # Test if credentials are accessible
      credentials_available = Rails.application.credentials.present?
      puts "   📋 Credentials available: #{credentials_available ? '✅' : '❌'}"
      
      # Test email section
      email_config = Rails.application.credentials.email
      if email_config
        puts "   📧 Email configuration found: ✅"
        puts "   🌐 SMTP Address: #{email_config[:smtp_address] || 'Not set'}"
        puts "   🔌 SMTP Port: #{email_config[:smtp_port] || 'Not set'}"
        puts "   👤 SMTP Username: #{email_config[:smtp_username] ? '✅ Set' : '❌ Not set'}"
        puts "   🔑 SMTP Password: #{email_config[:smtp_password] ? '✅ Set' : '❌ Not set'}"
        puts "   📨 Default From: #{email_config[:default_from] || 'Not set'}"
      else
        puts "   📧 Email configuration: ❌ Not found"
        puts "   💡 Add email config to credentials: rails credentials:edit --environment #{Rails.env}"
      end
      
    rescue => e
      puts "   ❌ Error loading credentials: #{e.message}"
    end
    
    puts
  end
  
  def self.test_email_configuration
    puts "⚙️ Testing Email Configuration..."
    
    begin
      # Get current email configuration
      smtp_settings = ActionMailer::Base.smtp_settings
      
      puts "   📮 Delivery method: #{ActionMailer::Base.delivery_method}"
      puts "   📤 Perform deliveries: #{ActionMailer::Base.perform_deliveries}"
      puts "   🌐 SMTP address: #{smtp_settings[:address]}"
      puts "   🔌 SMTP port: #{smtp_settings[:port]}"
      puts "   👤 Username: #{smtp_settings[:user_name] ? '✅ Set' : '❌ Missing'}"
      puts "   🔑 Password: #{smtp_settings[:password] ? '✅ Set' : '❌ Missing'}"
      
      # Test default from address
      default_from = UserMailer.default[:from]
      if default_from.respond_to?(:call)
        resolved_from = default_from.call
        puts "   📨 Default from (resolved): #{resolved_from}"
      else
        puts "   📨 Default from: #{default_from}"
      end
      
    rescue => e
      puts "   ❌ Error checking email config: #{e.message}"
    end
    
    puts
  end
  
  def self.test_email_with_credentials
    puts "📧 Testing Email with Credentials..."
    
    begin
      # Create test user
      test_user = User.new(
        full_name: "Credentials Test User",
        email: "test@example.com",
        password: "password123"
      )
      
      # Test welcome email
      puts "   🎉 Testing welcome email..."
      email = UserMailer.welcome_email(test_user)
      puts "   ✅ Welcome email created successfully"
      puts "   📨 From: #{email.from.first}"
      puts "   📬 To: #{email.to.first}"
      puts "   📝 Subject: #{email.subject}"
      
      # Try to deliver the email
      if ActionMailer::Base.smtp_settings[:user_name].present? && 
         ActionMailer::Base.smtp_settings[:password].present?
        puts "   📤 Attempting to send email..."
        email.deliver_now
        puts "   ✅ Email sent successfully!"
      else
        puts "   ⚠️ SMTP credentials missing - email not sent"
        puts "   💡 Configure credentials with: rails credentials:edit --environment #{Rails.env}"
      end
      
    rescue => e
      puts "   ❌ Email test failed: #{e.message}"
    end
    
    puts
  end
end

# Show usage instructions
def show_credentials_setup_instructions
  puts "\n📋 RAILS CREDENTIALS SETUP INSTRUCTIONS"
  puts "=" * 45
  puts
  puts "1️⃣ Edit credentials for current environment (#{Rails.env}):"
  puts "   EDITOR='nano' rails credentials:edit --environment #{Rails.env}"
  puts
  puts "2️⃣ Add this email configuration:"
  puts
  puts <<~YAML
    email:
      smtp_username: your-email@gmail.com
      smtp_password: your-app-password
      smtp_address: smtp.gmail.com
      smtp_port: 587
      smtp_domain: gmail.com
      default_from: noreply@tramate.com
  YAML
  puts
  puts "3️⃣ Save and exit the editor"
  puts "4️⃣ Run this test again: ruby test/rails_credentials_test.rb"
  puts
  puts "🔐 The credentials file will be encrypted and safe to commit to git!"
end

# Run the test if this file is executed directly
if __FILE__ == $0
  RailsCredentialsTest.run
  
  # Show setup instructions if credentials are missing
  email_config = Rails.application.credentials.email
  if email_config.nil? || email_config[:smtp_username].blank?
    show_credentials_setup_instructions
  end
end 