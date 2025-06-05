# 🔐 **TRAMATE RAILS CREDENTIALS GUIDE**

## 🎯 **OVERVIEW**

Rails credentials provide **encrypted, secure storage** for sensitive configuration data like email passwords, API keys, and other secrets. This guide shows you how to set up email configuration using Rails credentials instead of environment variables.

---

## ✅ **BENEFITS OF RAILS CREDENTIALS**

- 🔒 **Encrypted storage** - Safe to commit to git
- 🌍 **Environment-specific** - Different settings per environment
- 🔄 **Version controlled** - Track changes to configuration
- 🛡️ **Secure by default** - No plaintext secrets in code
- 🎯 **Centralized** - All secrets in one place

---

## 🚀 **QUICK SETUP**

### 1. **Generate Master Key & Edit Credentials**
```bash
# For development environment
EDITOR='nano' rails credentials:edit --environment development

# For production environment  
EDITOR='nano' rails credentials:edit --environment production
```

### 2. **Add Email Configuration**
```yaml
# Add this to your credentials file:
email:
  smtp_username: your-email@gmail.com
  smtp_password: your-app-password
  smtp_address: smtp.gmail.com
  smtp_port: 587
  smtp_domain: gmail.com
  default_from: noreply@tramate.com

# Optional: Add other secrets
production_domain: tramate.com
binance:
  api_key: your-binance-api-key
  api_secret: your-binance-api-secret
```

### 3. **Test Configuration**
```bash
ruby test/rails_credentials_test.rb
```

---

## 📁 **FILE STRUCTURE**

```
config/
├── credentials/
│   ├── development.yml.enc     # Encrypted development secrets
│   ├── development.key         # Development master key (gitignored)
│   ├── production.yml.enc      # Encrypted production secrets
│   └── production.key          # Production master key (gitignored)
├── credentials.yml.enc         # Default/shared encrypted secrets
└── master.key                  # Default master key (gitignored)
```

---

## 🔧 **DETAILED SETUP PROCESS**

### **Step 1: Install Prerequisites**
```bash
# Ensure you have Rails 6+ 
rails --version

# Choose your editor (pick one):
export EDITOR='nano'        # Simple terminal editor
export EDITOR='code --wait' # VS Code (if installed)
export EDITOR='vim'         # Vim editor
```

### **Step 2: Create Development Credentials**
```bash
# This creates encrypted credentials file for development
EDITOR='nano' rails credentials:edit --environment development
```

### **Step 3: Add Your Configuration**
```yaml
# In the editor, add your email settings:
email:
  smtp_username: your-email@gmail.com
  smtp_password: your-16-char-app-password
  smtp_address: smtp.gmail.com
  smtp_port: 587
  smtp_domain: gmail.com
  default_from: noreply@tramate.com

# Save and exit (Ctrl+X, then Y, then Enter in nano)
```

### **Step 4: Verify Setup**
```bash
# Test if credentials are working
ruby test/rails_credentials_test.rb

# Or check in Rails console
rails console
> Rails.application.credentials.email
```

---

## 🏭 **PRODUCTION SETUP**

### **Create Production Credentials**
```bash
EDITOR='nano' rails credentials:edit --environment production
```

### **Production Configuration Example**
```yaml
email:
  smtp_username: production@yourdomain.com
  smtp_password: your-production-smtp-password
  smtp_address: smtp.sendgrid.net  # or your SMTP provider
  smtp_port: 587
  smtp_domain: yourdomain.com
  default_from: noreply@yourdomain.com

production_domain: yourdomain.com

# Other production secrets
database_password: your-db-password
secret_key_base: your-long-secret-key

binance:
  api_key: your-production-binance-key
  api_secret: your-production-binance-secret
```

### **Deploy Master Key**
```bash
# Copy the master key to your production server
scp config/credentials/production.key user@server:/path/to/app/config/credentials/

# Or set as environment variable
export RAILS_MASTER_KEY="contents-of-production-key-file"
```

---

## 💻 **ACCESSING CREDENTIALS IN CODE**

### **Email Configuration (Already Updated)**
```ruby
# config/environments/development.rb & production.rb
email_config = Rails.application.credentials.email || {}

config.action_mailer.smtp_settings = {
  user_name: email_config[:smtp_username],
  password: email_config[:smtp_password],
  address: email_config[:smtp_address] || 'smtp.gmail.com',
  # ... etc
}
```

### **In Your Application Code**
```ruby
# Access email settings
Rails.application.credentials.email[:smtp_username]
Rails.application.credentials.email[:smtp_password]

# Access other secrets
Rails.application.credentials.binance[:api_key]
Rails.application.credentials.production_domain

# Safe access with fallback
Rails.application.credentials.dig(:email, :smtp_username) || 'fallback@example.com'
```

### **In Mailers**
```ruby
# app/mailers/user_mailer.rb (Already updated)
default from: -> { 
  Rails.application.credentials.dig(:email, :default_from) || 
  'noreply@tramate.com' 
}
```

---

## 🧪 **TESTING & VERIFICATION**

### **Test Scripts Available**
```bash
# Test Rails credentials specifically
ruby test/rails_credentials_test.rb

# Test overall email system
ruby test/email_notifications_test.rb

# Interactive setup
ruby setup_rails_credentials.rb
```

### **Manual Testing in Console**
```ruby
rails console

# Check if credentials loaded
Rails.application.credentials.present?

# View email config (passwords will be masked)
Rails.application.credentials.email

# Test email settings are applied
ActionMailer::Base.smtp_settings

# Test mailer default
UserMailer.default[:from].call
```

---

## 🔒 **SECURITY BEST PRACTICES**

### **Master Key Management**
- ✅ **Never commit** `.key` files to git
- ✅ **Store securely** - use password managers
- ✅ **Different keys** per environment
- ✅ **Backup safely** - encrypted storage
- ✅ **Rotate regularly** - especially if compromised

### **Gitignore Setup**
```bash
# Add to .gitignore (should already be there)
echo "config/master.key" >> .gitignore
echo "config/credentials/*.key" >> .gitignore
```

### **Team Collaboration**
```bash
# Share master keys securely (NOT in chat/email)
# Use: encrypted messaging, password managers, secure file sharing

# Each developer needs the key for their environment
# Development key: config/credentials/development.key
# Production key: config/credentials/production.key
```

---

## 🛠️ **TROUBLESHOOTING**

### **Common Issues**

#### **"Couldn't decrypt" Error**
```bash
# Missing or wrong master key
# Solution: Get the correct master key file or regenerate credentials

# Regenerate credentials (DESTROYS EXISTING DATA)
rm config/credentials/development.yml.enc
rm config/credentials/development.key
rails credentials:edit --environment development
```

#### **Credentials Not Loading**
```ruby
# Check in console
Rails.application.credentials.present?  # Should be true
Rails.env                              # Verify environment

# Check file exists
File.exist?("config/credentials/#{Rails.env}.yml.enc")
```

#### **SMTP Settings Not Applied**
```ruby
# Check in console
ActionMailer::Base.smtp_settings
# Should show your configured settings, not defaults
```

### **Debug Mode**
```ruby
# In development.rb, add logging
config.logger.level = :debug

# Check Rails logs for credential loading
tail -f log/development.log | grep -i credential
```

---

## 🔄 **MIGRATING FROM ENVIRONMENT VARIABLES**

### **Current Setup (Environment Variables)**
```bash
# .env file
GMAIL_USERNAME=your-email@gmail.com
GMAIL_PASSWORD=your-app-password
```

### **New Setup (Rails Credentials)**
```yaml
# rails credentials:edit --environment development
email:
  smtp_username: your-email@gmail.com
  smtp_password: your-app-password
```

### **Migration Steps**
1. ✅ Add credentials configuration
2. ✅ Test with credentials test script  
3. ✅ Verify emails still work
4. ✅ Remove environment variables
5. ✅ Update deployment scripts

---

## 📋 **CHEAT SHEET**

### **Essential Commands**
```bash
# Edit development credentials
rails credentials:edit --environment development

# Edit production credentials  
rails credentials:edit --environment production

# Show credentials content (masked)
rails credentials:show --environment development

# Test setup
ruby test/rails_credentials_test.rb
```

### **Accessing in Code**
```ruby
# Email settings
Rails.application.credentials.email[:smtp_username]
Rails.application.credentials.email[:smtp_password]

# Safe access
Rails.application.credentials.dig(:email, :smtp_username)

# With fallback
Rails.application.credentials.dig(:email, :default_from) || 'fallback@example.com'
```

---

## 🎯 **NEXT STEPS**

1. ✅ **Run setup script**: `ruby setup_rails_credentials.rb`
2. ✅ **Configure development**: Add your Gmail app password
3. ✅ **Test thoroughly**: Use the test scripts
4. ✅ **Set up production**: Create production credentials
5. ✅ **Deploy securely**: Share master keys safely

---

## 🆘 **NEED HELP?**

- 📖 **Rails Guides**: [Rails Credentials Documentation](https://guides.rubyonrails.org/security.html#custom-credentials)
- 🧪 **Test Scripts**: Run `ruby test/rails_credentials_test.rb`
- 🔧 **Setup Script**: Run `ruby setup_rails_credentials.rb`
- 📝 **Check Logs**: `tail -f log/development.log`

**Your email system is now secure and encrypted! 🎉** 