# 📧 **TRAMATE EMAIL NOTIFICATIONS SETUP GUIDE**

## 🎯 **OVERVIEW**

Your Tramate system now has **complete email notification support** for:
- ✅ **User Signup** - Welcome emails with onboarding info
- 🔐 **User Signin** - Security notifications with login details  
- 🚀 **Trade Executed** - Instant notifications when trades are placed
- 💰 **Trade Completed** - Profit/loss summaries when trades close
- ⚠️ **Trade Failed** - Error notifications with troubleshooting tips
- 📊 **Order Updates** - Fill confirmations and status changes

---

## 🔧 **QUICK SETUP (Gmail)**

### 1. **Generate Gmail App Password**
```bash
# Go to Google Account Settings
# Security → 2-Step Verification → App passwords
# Generate password for "Tramate App"
```

### 2. **Set Environment Variables**
```bash
# Add to your .env file or environment
export GMAIL_USERNAME="your-email@gmail.com"
export GMAIL_PASSWORD="your-16-char-app-password"
```

### 3. **Test Email System**
```bash
cd /home/mujeeb/Documents/Tramate
ruby test/email_notifications_test.rb
```

---

## 🚀 **PRODUCTION SETUP**

### **Environment Variables**
```bash
# Production SMTP Settings
SMTP_USERNAME=your-smtp-username
SMTP_PASSWORD=your-smtp-password  
SMTP_ADDRESS=smtp.gmail.com
SMTP_PORT=587
SMTP_DOMAIN=gmail.com
DOMAIN=tramate.com
```

### **Alternative SMTP Providers**

#### **SendGrid**
```bash
SMTP_ADDRESS=smtp.sendgrid.net
SMTP_PORT=587
SMTP_USERNAME=apikey
SMTP_PASSWORD=your-sendgrid-api-key
```

#### **Mailgun**
```bash
SMTP_ADDRESS=smtp.mailgun.org
SMTP_PORT=587
SMTP_USERNAME=your-mailgun-username
SMTP_PASSWORD=your-mailgun-password
```

#### **AWS SES**
```bash
SMTP_ADDRESS=email-smtp.us-east-1.amazonaws.com
SMTP_PORT=587
SMTP_USERNAME=your-ses-username
SMTP_PASSWORD=your-ses-password
```

---

## 📧 **EMAIL TEMPLATES**

### **Available Templates**
- `welcome_email.html.erb` - Beautiful welcome email with features overview
- `signin_notification.html.erb` - Security alert with login details
- `trade_executed.html.erb` - Trade confirmation with order details
- `trade_completed.html.erb` - Profit/loss summary with performance metrics
- `trade_failed.html.erb` - Error notification with troubleshooting steps

### **Customization**
```erb
<!-- Edit templates in app/views/user_mailer/ -->
<!-- Each template has both HTML and text versions -->
```

---

## 🔄 **EMAIL TRIGGERS**

### **Automatic Triggers**
```ruby
# User signup (automatic)
after_create :send_welcome_email

# User signin (automatic) 
user.send_signin_notification(request)

# Trade executed (automatic)
user.send_trade_notification(trade, :executed)

# Trade completed (automatic)
user.send_trade_notification(trade, :completed)

# Trade failed (automatic)
user.send_trade_notification(trade, :failed)
```

### **Manual Triggers**
```ruby
# Send welcome email manually
UserMailer.welcome_email(user).deliver_now

# Send signin notification
UserMailer.signin_notification(user, request).deliver_now

# Send trade notification
UserMailer.trade_executed(user, trade).deliver_now
```

---

## 🧪 **TESTING**

### **Run Email Tests**
```bash
cd /home/mujeeb/Documents/Tramate
ruby test/email_notifications_test.rb
```

### **Expected Output**
```
🧪 TRAMATE EMAIL NOTIFICATIONS TEST
============================================================

🔧 Testing Email Configuration...
   📤 Email delivery enabled: ✅
   📮 Delivery method: smtp
   🌐 SMTP server: smtp.gmail.com:587
   👤 SMTP username: ✅ Set
   🔑 SMTP password: ✅ Set

📧 Testing Welcome Email...
   ✅ Welcome email sent successfully

🔐 Testing Signin Notification...
   ✅ Signin notification sent successfully

📈 Testing Trade Notifications...
   🚀 Testing trade executed notification...
   ✅ Trade executed email sent
   💰 Testing trade completed notification (profit)...
   ✅ Trade completed (profit) email sent
   📉 Testing trade completed notification (loss)...
   ✅ Trade completed (loss) email sent
   ⚠️ Testing trade failed notification...
   ✅ Trade failed email sent

✅ EMAIL NOTIFICATIONS TEST COMPLETED!
```

---

## 🛠️ **TROUBLESHOOTING**

### **Common Issues**

#### **Emails Not Sending**
```bash
# Check Rails logs
tail -f log/development.log

# Verify SMTP settings
rails console
> ActionMailer::Base.smtp_settings
```

#### **Gmail Authentication Errors**
```bash
# Ensure 2FA is enabled
# Use App Password, not regular password
# Check "Less secure app access" if needed
```

#### **Delivery Failures**
```ruby
# Check delivery errors in Rails console
ActionMailer::Base.raise_delivery_errors = true
```

### **Debug Mode**
```ruby
# Enable detailed email logging
config.action_mailer.logger = Logger.new(STDOUT)
config.log_level = :debug
```

---

## 📊 **EMAIL ANALYTICS**

### **Track Email Performance**
```ruby
# Add to ApplicationMailer for tracking
class ApplicationMailer < ActionMailer::Base
  after_action :log_email_sent
  
  private
  
  def log_email_sent
    Rails.logger.info "Email sent: #{message.subject} to #{message.to}"
  end
end
```

### **Monitor Delivery**
```bash
# Check email delivery logs
grep "Email sent" log/production.log
```

---

## 🔐 **SECURITY BEST PRACTICES**

### **Environment Variables**
```bash
# Never commit email credentials to git
# Use environment variables or Rails credentials
# Rotate passwords regularly
```

### **Email Content**
```ruby
# Don't include sensitive data in emails
# Use secure links with tokens
# Implement email verification for critical actions
```

---

## 🎯 **NEXT STEPS**

1. **Set up your email credentials** using the Quick Setup guide
2. **Run the email test** to verify everything works
3. **Customize email templates** to match your brand
4. **Monitor email delivery** in production
5. **Set up email analytics** for performance tracking

---

## 📞 **SUPPORT**

If you encounter issues:
1. Check the troubleshooting section above
2. Review Rails logs for error details
3. Test with the provided email test script
4. Verify SMTP credentials and settings

**Your email notification system is now ready! 🎉** 