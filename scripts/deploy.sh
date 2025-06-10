#!/bin/bash

# Tramate Deployment Script
# Production deployment automation with comprehensive checks and rollback capability

set -euo pipefail

# Configuration
PROJECT_NAME="tramate"
DOCKER_COMPOSE_FILE="docker-compose.yml"
ENV_FILE=".env"
BACKUP_DIR="./backups"
LOG_FILE="./logs/deploy.log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "${LOG_FILE}"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "${LOG_FILE}"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1" | tee -a "${LOG_FILE}"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a "${LOG_FILE}"
}

# Create necessary directories
mkdir -p logs backups

# Pre-deployment checks
pre_deployment_checks() {
    log "Running pre-deployment checks..."
    
    # Check if Docker is running
    if ! docker info >/dev/null 2>&1; then
        error "Docker is not running. Please start Docker and try again."
        exit 1
    fi
    
    # Check if environment file exists
    if [[ ! -f "$ENV_FILE" ]]; then
        error "Environment file '$ENV_FILE' not found. Please create it from .env.example"
        exit 1
    fi
    
    # Check if docker-compose.yml exists
    if [[ ! -f "$DOCKER_COMPOSE_FILE" ]]; then
        error "Docker Compose file '$DOCKER_COMPOSE_FILE' not found."
        exit 1
    fi
    
    # Validate environment variables
    log "Validating environment variables..."
    required_vars=(
        "RAILS_ENV"
        "SECRET_KEY_BASE"
        "DATABASE_URL"
        "REDIS_URL"
        "DISCORD_BOT_TOKEN"
        "BINANCE_API_KEY"
        "BINANCE_SECRET_KEY"
    )
    
    for var in "${required_vars[@]}"; do
        if ! grep -q "^${var}=" "$ENV_FILE"; then
            error "Required environment variable '$var' not found in $ENV_FILE"
            exit 1
        fi
    done
    
    success "Pre-deployment checks passed"
}

# Database backup
backup_database() {
    log "Creating database backup..."
    
    local backup_file="${BACKUP_DIR}/tramate_backup_$(date +%Y%m%d_%H%M%S).sql"
    
    # Create backup using docker-compose
    if docker-compose exec -T postgres pg_dump -U postgres tramate_production > "$backup_file" 2>/dev/null; then
        success "Database backup created: $backup_file"
        echo "$backup_file" > "${BACKUP_DIR}/latest_backup.txt"
    else
        warning "Failed to create database backup. Continuing with deployment..."
    fi
}

# Build and deploy
deploy() {
    log "Starting deployment process..."
    
    # Pull latest images
    log "Pulling latest images..."
    docker-compose pull
    
    # Build application image
    log "Building application image..."
    docker-compose build --no-cache web
    
    # Stop existing services gracefully
    log "Stopping existing services..."
    docker-compose down --timeout 30
    
    # Start services
    log "Starting services..."
    docker-compose up -d
    
    # Wait for services to be ready
    wait_for_services
}

# Wait for services to be healthy
wait_for_services() {
    log "Waiting for services to be ready..."
    
    local max_attempts=60
    local attempt=1
    
    while [[ $attempt -le $max_attempts ]]; do
        if check_health; then
            success "All services are healthy"
            return 0
        fi
        
        log "Attempt $attempt/$max_attempts - Services not ready yet, waiting..."
        sleep 5
        ((attempt++))
    done
    
    error "Services failed to become healthy within timeout"
    return 1
}

# Health check
check_health() {
    local healthy=true
    
    # Check web service
    if ! curl -sf http://localhost/health >/dev/null 2>&1; then
        healthy=false
    fi
    
    # Check database
    if ! docker-compose exec -T postgres pg_isready -U postgres >/dev/null 2>&1; then
        healthy=false
    fi
    
    # Check Redis
    if ! docker-compose exec -T redis redis-cli ping >/dev/null 2>&1; then
        healthy=false
    fi
    
    $healthy
}

# Post-deployment tasks
post_deployment_tasks() {
    log "Running post-deployment tasks..."
    
    # Run database migrations
    log "Running database migrations..."
    docker-compose exec web bundle exec rails db:migrate
    
    # Clear cache
    log "Clearing application cache..."
    docker-compose exec web bundle exec rails cache:clear
    
    # Restart background jobs
    log "Restarting Sidekiq..."
    docker-compose restart sidekiq
    
    success "Post-deployment tasks completed"
}

# Rollback function
rollback() {
    error "Deployment failed. Starting rollback process..."
    
    # Stop current services
    docker-compose down --timeout 30
    
    # Restore from backup if available
    if [[ -f "${BACKUP_DIR}/latest_backup.txt" ]]; then
        local backup_file
        backup_file=$(cat "${BACKUP_DIR}/latest_backup.txt")
        
        if [[ -f "$backup_file" ]]; then
            log "Restoring database from backup: $backup_file"
            # Start only database for restore
            docker-compose up -d postgres
            sleep 10
            
            # Restore database
            cat "$backup_file" | docker-compose exec -T postgres psql -U postgres tramate_production
            
            success "Database restored from backup"
        fi
    fi
    
    error "Rollback completed. Please check the logs and fix issues before trying again."
    exit 1
}

# Cleanup old images and containers
cleanup() {
    log "Cleaning up old Docker resources..."
    
    # Remove unused images
    docker image prune -f
    
    # Remove old backups (keep last 7 days)
    find "${BACKUP_DIR}" -name "*.sql" -mtime +7 -delete
    
    success "Cleanup completed"
}

# Main deployment flow
main() {
    log "=== Starting Tramate Deployment ==="
    
    # Set trap for rollback on failure
    trap rollback ERR
    
    pre_deployment_checks
    backup_database
    deploy
    post_deployment_tasks
    cleanup
    
    success "=== Deployment completed successfully ==="
    
    # Show service status
    log "Service status:"
    docker-compose ps
    
    log "Application is available at: http://localhost"
    log "Health check: http://localhost/health"
}

# Script execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
