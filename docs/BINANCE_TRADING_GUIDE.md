# Binance Trading System Guide

## Overview

This document explains the comprehensive Binance trading system that automatically executes trades based on Discord signals using the official Binance REST API.

## Architecture

### 1. Signal Processing Flow

```
Discord Message → TradeSignal → SignalProcessor → ExecuteTradeJob → BinanceService → Binance API
```

### 2. Key Components

#### BinanceService (`app/services/binance_service.rb`)
- Uses official `binance-connector-ruby` gem
- Implements all Binance REST API endpoints
- Supports both testnet and mainnet
- Proper error handling and rate limiting
- Follows official API documentation

#### SignalProcessor (`app/services/signal_processor.rb`)
- Parses various Discord signal formats
- Extracts trading parameters (symbol, entry, TP, SL)
- Calculates confidence scores and risk/reward ratios
- Supports multiple signal patterns

#### TradeExecutor (`app/services/binance/trade_executor.rb`)
- Executes trades based on processed signals
- Handles position sizing and risk management
- Places entry, take profit, and stop loss orders
- Validates orders against Binance requirements

## Supported Signal Formats

### 1. Standard Format
```
🚀 BTC LONG Entry: $45000 TP: $47000 SL: $43000
```

### 2. Coin Format
```
Coin: ETH Entry Price: 3000 Take Profit: 3200 Stop Loss: 2800
```

### 3. Brief Format
```
BTC 45000-47000 SL:43000
```

### 4. Multiple Take Profit
```
BTC LONG Entry: 45000 TP1: 46000 TP2: 47000 TP3: 48000 SL: 43000
```

### 5. Spot Format
```
💰 BTCUSDT BUY 45000 Target 47000
```

## API Configuration

### Testnet vs Mainnet

The system automatically uses testnet in development:

```ruby
# config/initializers/binance_api.rb
config.binance_testnet = Rails.env.development? || Rails.env.test? || ENV['BINANCE_TESTNET'] == 'true'
```

### Rate Limits

Configured according to Binance API limits:
- 1200 requests per minute
- 10 orders per second
- 200,000 orders per 24 hours

## Order Types Supported

### Entry Orders
- **MARKET**: For urgent signals or when price is very close to entry
- **LIMIT**: For precise entry prices
- **LIMIT_MAKER**: Post-only orders (optional)

### Exit Orders
- **LIMIT**: Take profit orders
- **STOP_LOSS_LIMIT**: Stop loss orders

## Trading Process

### 1. Signal Creation
When a Discord message is received:
```ruby
signal = channel.trade_signals.create!(
  message_content: event.message.content,
  parsed_data: {}
)
```

### 2. Signal Processing
Automatically triggered via `after_create` callback:
```ruby
ProcessSignalJob.perform_later(signal.id)
```

### 3. Signal Parsing
```ruby
processor = SignalProcessor.new(message_content)
if processor.valid?
  signal.parsed_data = processor.to_h
  signal.confidence_score = processor.confidence_score
end
```

### 4. Trade Execution
For each eligible user:
```ruby
executor = Binance::TradeExecutor.new(user, api_credential)
result = executor.execute_signal_trade(signal)
```

### 5. Order Monitoring
```ruby
MonitorTradeJob.perform_in(30.seconds, trade.id)
```

## Risk Management

### Position Sizing
- Fixed amount per trade
- Percentage of account balance
- Maximum trade limits
- Minimum balance requirements

### Order Validation
- Symbol validation against exchange info
- Minimum quantity requirements
- Minimum notional value checks
- Price precision validation

### Error Handling
- Comprehensive error mapping
- Retry mechanisms for server errors
- Failed trade tracking
- User notifications

## Database Schema

### TradeSignal Model
```ruby
# Enhanced fields for signal processing
add_column :trade_signals, :status, :string, default: 'pending'
add_column :trade_signals, :signal_type, :string
add_column :trade_signals, :confidence_score, :decimal, precision: 5, scale: 3
add_column :trade_signals, :error_message, :text
add_column :trade_signals, :urgency, :string
add_column :trade_signals, :risk_reward_ratio, :decimal, precision: 8, scale: 2
```

### Trade Model
Tracks individual user trades with:
- Binance order IDs
- Execution details
- Take profit/stop loss orders
- Profit/loss calculations

## Testing

### Integration Test
```bash
ruby test/binance_integration_test.rb
```

Tests:
1. API connectivity
2. Signal processing
3. Service initialization

### Signal Processing Test
```ruby
processor = SignalProcessor.new("🚀 BTC LONG Entry: $45000 TP: $47000 SL: $43000")
puts processor.valid? # => true
puts processor.to_h[:symbol] # => "BTC"
```

## Configuration

### Environment Variables
```bash
BINANCE_TESTNET=true  # Use testnet
DISCORD_BOT_TOKEN=your_token
DISCORD_CLIENT_ID=your_client_id
```

### User Settings
```ruby
trade_settings = {
  position_sizing_method: 'fixed_amount',
  fixed_amount: 50.0,
  account_percentage: 5.0,
  max_trade_amount: 500.0,
  min_trade_amount: 10.0,
  prefer_market_orders: false,
  use_post_only_orders: false,
  risk_management_enabled: true
}
```

## API Endpoints Used

### General Endpoints
- `GET /api/v3/ping` - Connectivity test
- `GET /api/v3/time` - Server time
- `GET /api/v3/exchangeInfo` - Symbol information

### Account Endpoints
- `GET /api/v3/account` - Account information

### Trading Endpoints
- `POST /api/v3/order` - New order
- `POST /api/v3/order/test` - Test new order
- `GET /api/v3/order` - Query order
- `DELETE /api/v3/order` - Cancel order
- `GET /api/v3/openOrders` - Current open orders

## Error Handling

### Binance API Errors
- `-2014`: Invalid API key format
- `-1021`: Timestamp outside receive window
- `-1022`: Invalid signature
- `-2015`: Invalid API key or permissions
- `-1003`: Too many requests
- `-2010`: Insufficient balance
- `-1013`: Invalid quantity/price precision
- `-1111`: Invalid symbol

### Retry Logic
- Client errors: 3 attempts with exponential backoff
- Server errors: 5 attempts with 30-second intervals
- General errors: 2 attempts with 10-second intervals

## Monitoring

### Trade Status Tracking
- `pending` - Order placed but not filled
- `executed` - Entry order filled
- `completed` - Exit order filled (TP/SL)
- `failed` - Order failed or rejected

### Logging
All trading activities are logged with:
- Signal processing results
- Order execution details
- Error messages and stack traces
- Performance metrics

## Security

### API Key Management
- Encrypted storage of API secrets
- Limited permissions (spot trading only)
- No withdrawal permissions required
- Testnet support for development

### Rate Limiting
- Built-in rate limiting per Binance requirements
- Request queuing and throttling
- Error handling for rate limit exceeded

## Deployment

### Production Checklist
1. Set `BINANCE_TESTNET=false`
2. Configure production API keys
3. Set up monitoring and alerting
4. Configure backup and recovery
5. Test with small amounts first

### Monitoring Setup
- Track trade success rates
- Monitor API response times
- Alert on failed trades
- Log analysis for optimization

## Troubleshooting

### Common Issues
1. **Signal not parsing**: Check signal format against supported patterns
2. **Order rejected**: Verify symbol, quantity, and price precision
3. **Insufficient balance**: Check USDT balance and minimum requirements
4. **API errors**: Verify API key permissions and rate limits

### Debug Commands
```ruby
# Test signal processing
processor = SignalProcessor.new("your_signal_text")
puts processor.to_h

# Test API connectivity
service = BinanceService.new(api_key, api_secret)
puts service.test_connectivity

# Check account info
result = service.get_account_info
puts result[:data] if result[:success]
```

This comprehensive trading system provides robust, scalable, and secure automated trading based on Discord signals using the official Binance API. 