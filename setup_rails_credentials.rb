#!/usr/bin/env ruby

# Rails Credentials Setup Script for Email Configuration
# This script guides you through setting up encrypted email credentials in Rails

puts "🔐 TRAMATE RAILS CREDENTIALS SETUP"
puts "=" * 50
puts

puts "🎯 WHY USE RAILS CREDENTIALS?"
puts "✅ Encrypted storage in your repository"
puts "✅ Version controlled (encrypted files)"
puts "✅ No need for separate .env files"
puts "✅ Different credentials per environment"
puts "✅ More secure than environment variables"
puts

puts "📋 SETUP PROCESS"
puts "=" * 20

puts "\n1️⃣ MASTER KEY"
puts "Rails uses a master key to encrypt/decrypt credentials."
puts "This key should be kept secret and not committed to git."

puts "\n2️⃣ ENVIRONMENT-SPECIFIC CREDENTIALS"
puts "You can have separate credentials for:"
puts "   - Development (config/credentials/development.yml.enc)"
puts "   - Production (config/credentials/production.yml.enc)"
puts "   - Test (config/credentials/test.yml.enc)"

puts "\n3️⃣ ACCESSING CREDENTIALS IN CODE"
puts "Use: Rails.application.credentials.email.smtp_username"

puts "\n🚀 LET'S START SETUP"
puts "=" * 25

print "\nDo you want to set up Rails credentials now? (y/n): "
response = gets.chomp.downcase

if response == 'y' || response == 'yes'
  puts "\n📝 STEP 1: Generate Master Key (if not exists)"
  puts "Run this command:"
  puts "   rails credentials:edit"
  puts "   (This will create master key automatically)"
  
  puts "\n📝 STEP 2: Create Development Credentials"
  puts "Run this command:"
  puts "   EDITOR='code --wait' rails credentials:edit --environment development"
  puts "   (Replace 'code' with your preferred editor: nano, vim, etc.)"
  
  puts "\n📝 STEP 3: Add Email Configuration"
  puts "Add this structure to your credentials file:"
  puts

  puts <<~YAML
    # Development credentials example:
    email:
      smtp_username: your-email@gmail.com
      smtp_password: your-app-password
      smtp_address: smtp.gmail.com
      smtp_port: 587
      smtp_domain: gmail.com
      default_from: noreply@tramate.com

    # For production, add additional settings:
    # production_domain: tramate.com
    # binance_api_key: your-binance-key
    # binance_api_secret: your-binance-secret
  YAML

  puts "\n📝 STEP 4: Update Rails Configuration"
  puts "I'll update your Rails config files to use credentials..."
  
  print "\nPress Enter to continue with config file updates..."
  gets
  
  puts "\n✅ Configuration files will be updated!"
  puts "🔄 Next: Run the credential editing commands above"
else
  puts "\n📚 MANUAL SETUP INSTRUCTIONS"
  puts "1. Run: rails credentials:edit"
  puts "2. Run: rails credentials:edit --environment development"
  puts "3. Add your email configuration to the credentials"
  puts "4. Update your Rails config files to use credentials"
end

puts "\n🎯 NEXT STEPS AFTER SETUP"
puts "=" * 30
puts "1. Edit credentials: rails credentials:edit --environment development"
puts "2. Add your email settings to the credentials file"
puts "3. Test with: ruby test/email_notifications_test.rb"
puts "4. Deploy master key securely to production"

puts "\n🔒 SECURITY NOTES"
puts "=" * 18
puts "• Master key files (master.key, development.key) should NOT be committed"
puts "• Add *.key to your .gitignore"
puts "• Share master keys securely with team members"
puts "• Use different credentials for each environment"

puts "\n🎉 Rails credentials setup guide complete!" 