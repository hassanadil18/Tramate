# Tramate Platform

A platform to connect Discord and Binance for automated trading based on signals.

## Technology Stack

- **Backend**: Ruby on Rails
- **Database**: PostgreSQL
- **Deployment**: Docker and Kamal
- **APIs**: Discord and Binance integrations
- **Authentication**: Custom user authentication system

## Features Implemented

- **User Management**
  - User registration and authentication
  - User profile management
  - Admin and regular user roles

- **Discord Integration**
  - Discord bot for monitoring channels
  - Signal parsing from Discord messages
  - Channel access management

- **Binance Trading**
  - Secure API credential storage
  - Automated trade execution
  - Trading history and performance tracking

- **Admin Dashboard**
  - User management
  - Channel configuration
  - Trade monitoring
  - System logs and diagnostics

- **Payment Processing**
  - Subscription management
  - Payment tracking

## Remaining Features

- **Full Admin Dashboard**
  - Trade monitoring view
  - System logs and diagnostics

- **Error Handling**
  - Global try/catch and error messages
  - User-friendly feedback for failed operations

- **Queue & Retry Mechanisms**
  - Retry logic for failed API requests (Discord/Binance)
  - Message queue handling for high-volume trades/signals

- **Scalability Preparations**
  - Codebase ready for multi-channel support
  - Support for adding multiple exchanges

- **Trade History Visualization**
  - User view for past trades with success/failure status
  - Performance summary or analytics

- **Project Documentation**
  - Technical README (setup, deployment, usage)
  - API usage and bot configuration instructions

## Setup

1. Clone the repository
2. Run `bundle install`
3. Set up the database with `rails db:create db:migrate`
4. Configure Discord and Binance API keys in `config/initializers`
5. Start the server with `rails server`

## Development

The project follows standard Rails conventions with additional services for third-party integrations. The main workflow involves:
1. Discord bot monitoring channels for trading signals
2. Signal parsing and validation
3. Trade execution on Binance based on validated signals
4. Performance tracking and reporting




## Email Notifications

Tramate now supports email notifications for login and signup events. To configure email delivery:

### Development Environment

In development, emails are displayed in the browser using the `letter_opener` gem instead of being sent. This allows for easy testing without configuring an actual email provider.

1. Run `bundle install` to install the letter_opener gem
2. Start the Rails server
3. When a user logs in or signs up, the email will be displayed in a new browser tab

### Production Environment

For production, you need to set up SMTP credentials for Gmail or another email provider:

1. Edit your credentials file:
   ```
   EDITOR=nano rails credentials:edit
   ```

2. Add your SMTP credentials in this format:
   ```yaml
   smtp:
     user_name: your_email@gmail.com
     password: your_app_password
   ```

   Note: For Gmail, you need to use an App Password, not your regular Gmail password. You can generate one at https://myaccount.google.com/apppasswords

3. Deploy your application with the updated credentials

The system will automatically send email notifications when users log in or create new accounts.
