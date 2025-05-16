# Tramate Platform

A platform to connect Discord and Binance for automated trading based on signals.

## Project Overview

Tramate is a Rails-based web application that allows users to:
- Connect to Discord servers to receive trading signals
- Connect to Binance accounts for automated cryptocurrency trading
- Execute trades automatically based on signals from Discord channels
- Manage subscriptions and track trading performance

## Technology Stack

- **Backend**: Ruby on Rails
- **Database**: PostgreSQL
- **Deployment**: Docker and Kamal
- **APIs**: Discord and Binance integrations
- **Authentication**: Custom user authentication system

## Project Structure

- **app/models**: Core data models for users, signals, trades, channels, and API credentials
- **app/controllers**: Application logic for user authentication, dashboard, and admin functions
- **app/services**: Service classes for Discord bot integration and Binance trading API
- **app/views**: User interfaces for the web application
- **config**: Application configuration files
- **db/migrate**: Database schema and migrations

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


