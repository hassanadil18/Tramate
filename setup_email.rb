#!/usr/bin/env ruby

# Email Setup Script for Tramate
# This script helps you configure email notifications

puts "🚀 TRAMATE EMAIL SETUP"
puts "=" * 50
puts

puts "This script will help you set up email notifications for:"
puts "✅ User signup welcome emails"
puts "🔐 User signin security notifications"
puts "📈 Trade execution alerts"
puts "💰 Trade completion summaries"
puts "⚠️ Trade failure notifications"
puts

puts "📧 EMAIL PROVIDER SETUP"
puts "=" * 30

puts "\n1. GMAIL SETUP (Recommended for testing)"
puts "   - Go to Google Account Settings"
puts "   - Security → 2-Step Verification → App passwords"
puts "   - Generate password for 'Tramate App'"
puts "   - Copy the 16-character password"

puts "\n2. SET ENVIRONMENT VARIABLES"
puts "   Add these to your .env file or environment:"
puts

puts "   # For Gmail:"
puts "   export GMAIL_USERNAME=\"your-email@gmail.com\""
puts "   export GMAIL_PASSWORD=\"your-16-char-app-password\""

puts "\n   # For Production (any SMTP provider):"
puts "   export SMTP_USERNAME=\"your-smtp-username\""
puts "   export SMTP_PASSWORD=\"your-smtp-password\""
puts "   export SMTP_ADDRESS=\"smtp.gmail.com\""
puts "   export SMTP_PORT=\"587\""
puts "   export SMTP_DOMAIN=\"gmail.com\""
puts "   export DOMAIN=\"tramate.com\""

puts "\n3. TEST YOUR SETUP"
puts "   Run this command to test email notifications:"
puts "   ruby test/email_notifications_test.rb"

puts "\n🔧 QUICK GMAIL SETUP"
puts "=" * 20

print "\nDo you want to set up Gmail now? (y/n): "
response = gets.chomp.downcase

if response == 'y' || response == 'yes'
  print "Enter your Gmail address: "
  gmail_username = gets.chomp
  
  print "Enter your Gmail App Password (16 characters): "
  gmail_password = gets.chomp
  
  # Create or update .env file
  env_content = []
  
  if File.exist?('.env')
    env_content = File.readlines('.env')
    # Remove existing Gmail settings
    env_content.reject! { |line| line.start_with?('GMAIL_USERNAME=') || line.start_with?('GMAIL_PASSWORD=') }
  end
  
  env_content << "GMAIL_USERNAME=#{gmail_username}\n"
  env_content << "GMAIL_PASSWORD=#{gmail_password}\n"
  
  File.write('.env', env_content.join)
  
  puts "\n✅ Gmail configuration saved to .env file!"
  puts "🧪 Now run: ruby test/email_notifications_test.rb"
else
  puts "\n📝 Manual setup:"
  puts "1. Create a .env file in your project root"
  puts "2. Add your email credentials"
  puts "3. Run the test script to verify"
end

puts "\n🎯 NEXT STEPS"
puts "=" * 15
puts "1. Set up your email credentials (above)"
puts "2. Test with: ruby test/email_notifications_test.rb"
puts "3. Check your email inbox for test messages"
puts "4. Your users will now receive automatic notifications!"

puts "\n📞 NEED HELP?"
puts "Check EMAIL_SETUP_GUIDE.md for detailed instructions"
puts "and troubleshooting tips."

puts "\n🎉 Email notifications are ready to use!" 