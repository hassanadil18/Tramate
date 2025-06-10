# Tramate Production Deployment README
# Complete guide for deploying the Tramate trading platform

## 🚀 Quick Start

The Tramate platform is now equipped with a comprehensive Docker-based deployment system designed for production environments. This setup provides enterprise-grade features including monitoring, logging, security, and automated backups.

## 📋 Prerequisites

- Ubuntu 20.04+ or similar Linux distribution
- Minimum 4GB RAM, 2 CPU cores
- 50GB+ available disk space
- Root access for initial setup
- Domain name (optional, for SSL)

## 🛠 Installation

### 1. Automated Setup (Recommended)

```bash
# Download and run the production setup script
curl -fsSL https://raw.githubusercontent.com/yourusername/tramate/main/scripts/production-setup.sh | sudo bash
```

### 2. Manual Setup

```bash
# Clone the repository
git clone https://github.com/yourusername/tramate.git /opt/tramate
cd /opt/tramate

# Make scripts executable
chmod +x scripts/*.sh

# Run individual setup components
sudo ./scripts/production-setup.sh
```

## ⚙️ Configuration

### Environment Variables

Copy the example environment file and configure your settings:

```bash
cp .env.example .env
vim .env
```

**Required Variables:**
- `RAILS_ENV=production`
- `SECRET_KEY_BASE` - Generate with `rails secret`
- `DATABASE_URL` - PostgreSQL connection string
- `REDIS_URL` - Redis connection string
- `DISCORD_BOT_TOKEN` - Your Discord bot token
- `BINANCE_API_KEY` - Binance API key
- `BINANCE_SECRET_KEY` - Binance API secret

### SSL Configuration (Optional)

For HTTPS support, set your domain in the setup script:

```bash
# Edit the production-setup.sh script
DOMAIN="your-domain.com"
```

## 🚀 Deployment

### Initial Deployment

```bash
cd /opt/tramate
./scripts/deploy.sh
```

### Monitoring Deployment

```bash
# Start monitoring stack
docker-compose -f docker-compose.monitoring.yml up -d

# View logs
docker-compose logs -f
```

## 📊 Monitoring & Logging

### Access Monitoring Interfaces
- **Application**: http://your-domain.com
- **Grafana (Metrics)**: http://your-domain.com:3000
  - Username: admin
  - Password: admin123
- **Kibana (Logs)**: http://your-domain.com:5601
- **Prometheus**: http://your-domain.com:9090

### Health Checks
```bash
# Check application health
curl http://localhost/health

# Check all services
./scripts/monitor.sh health

# View service status
docker-compose ps
```

## 🔧 Maintenance

### Backup Operations

```bash
# Create full backup
./scripts/backup.sh full-backup

# Database backup only
./scripts/backup.sh db-backup

# List available backups
./scripts/backup.sh list

# Restore from backup
./scripts/backup.sh restore backup-file.tar.gz
```

### Monitoring Operations

```bash
# Run monitoring check
./scripts/monitor.sh monitor

# Continuous monitoring
./scripts/monitor.sh continuous

# Generate status report
./scripts/monitor.sh report
```

### Log Management

```bash
# View application logs
docker-compose logs web

# View all service logs
docker-compose logs

# Follow logs in real-time
docker-compose logs -f
```

## 🔒 Security Features

### Built-in Security
- Non-root container execution
- Security headers via Nginx
- Rate limiting and DDoS protection
- SSL/TLS encryption support
- Firewall configuration
- Automated security updates

### Security Monitoring
- Failed login attempt tracking
- Suspicious activity detection
- Automated security alerts
- Vulnerability scanning in CI/CD

## 📈 Performance Optimization

### Application Performance
- Ruby YJIT compilation
- jemalloc memory allocator
- Optimized garbage collection
- Database query optimization
- Redis caching layer

### Infrastructure Performance
- Multi-stage Docker builds
- Image layer caching
- Nginx reverse proxy with caching
- Load balancing ready
- Horizontal scaling support

## 🔄 CI/CD Pipeline

### GitHub Actions Integration
The platform includes a comprehensive CI/CD pipeline:

```yaml
# Automated on push to main/develop
- Code quality checks (RuboCop, Brakeman)
- Automated testing (RSpec)
- Security scanning (Trivy)
- Docker image building and pushing
- Automated deployment to staging/production
- Smoke tests post-deployment
- Slack notifications
```

### Manual Deployment
```bash
# Deploy latest changes
git pull origin main
./scripts/deploy.sh
```

## 🚨 Troubleshooting

### Common Issues

**Services Not Starting:**
```bash
# Check Docker daemon
sudo systemctl status docker

# Check container logs
docker-compose logs [service-name]

# Restart services
docker-compose restart
```

**Database Connection Issues:**
```bash
# Check database status
docker-compose exec postgres pg_isready -U postgres

# Reset database connection
docker-compose restart postgres web
```

**High Resource Usage:**
```bash
# Monitor resource usage
docker stats

# Check system resources
./scripts/monitor.sh resources
```

### Log Locations
- Application logs: `./logs/`
- Docker logs: `docker-compose logs`
- System logs: `/var/log/`
- Backup logs: `./logs/backup.log`
- Deployment logs: `./logs/deploy.log`

## 🔧 Advanced Configuration

### Custom Nginx Configuration
Edit `nginx/conf.d/tramate.conf` for custom Nginx settings.

### Database Tuning
Modify `docker-compose.yml` PostgreSQL settings for your workload.

### Redis Configuration
Customize Redis settings in `docker-compose.yml`.

### Monitoring Alerts
Configure alert rules in `prometheus/alert_rules.yml`.

## 📞 Support

### Resources
- Health endpoint: `/health`
- Metrics endpoint: `/metrics`
- API documentation: `/api/docs`

### Getting Help
1. Check the logs: `./scripts/monitor.sh report`
2. Verify configuration: `docker-compose config`
3. Test connectivity: `./scripts/monitor.sh health`

## 🏗 Architecture Overview

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│     Nginx       │────│   Rails App     │────│   PostgreSQL    │
│  (Reverse Proxy)│    │   (Tramate)     │    │   (Database)    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         │              ┌─────────────────┐              │
         │              │     Redis       │              │
         │              │    (Cache)      │              │
         │              └─────────────────┘              │
         │                       │                       │
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│    Grafana      │    │   Prometheus     │    │     Sidekiq     │
│  (Dashboards)   │    │   (Metrics)     │    │ (Background Jobs)│
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

This production-ready setup ensures your Tramate trading platform runs reliably, securely, and with comprehensive monitoring capabilities.

## 📄 License

This deployment configuration is part of the Tramate platform. Please refer to the main project license for details.
