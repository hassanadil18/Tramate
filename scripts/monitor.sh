#!/bin/bash

# Tramate Monitoring and Maintenance Script
# Comprehensive monitoring, logging, and maintenance automation

set -euo pipefail

# Configuration
PROJECT_NAME="tramate"
LOG_DIR="./logs"
METRICS_DIR="./metrics"
ALERT_EMAIL=""  # Set your alert email
SLACK_WEBHOOK=""  # Set your Slack webhook URL

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Create directories
mkdir -p "$LOG_DIR" "$METRICS_DIR"

# Logging
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "${LOG_DIR}/monitor.log"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "${LOG_DIR}/monitor.log"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1" | tee -a "${LOG_DIR}/monitor.log"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a "${LOG_DIR}/monitor.log"
}

# Send alert
send_alert() {
    local message="$1"
    local severity="${2:-warning}"
    
    # Log the alert
    case $severity in
        "critical")
            error "CRITICAL ALERT: $message"
            ;;
        "warning")
            warning "WARNING ALERT: $message"
            ;;
        *)
            log "INFO ALERT: $message"
            ;;
    esac
    
    # Send email if configured
    if [[ -n "$ALERT_EMAIL" ]]; then
        echo "$message" | mail -s "Tramate Alert [$severity]" "$ALERT_EMAIL" 2>/dev/null || true
    fi
    
    # Send to Slack if configured
    if [[ -n "$SLACK_WEBHOOK" ]]; then
        local color
        case $severity in
            "critical") color="danger" ;;
            "warning") color="warning" ;;
            *) color="good" ;;
        esac
        
        curl -X POST -H 'Content-type: application/json' \
            --data "{\"attachments\":[{\"color\":\"$color\",\"text\":\"$message\"}]}" \
            "$SLACK_WEBHOOK" 2>/dev/null || true
    fi
}

# Check service health
check_service_health() {
    log "Checking service health..."
    
    local unhealthy_services=()
    
    # Check web service
    if ! curl -sf http://localhost/health >/dev/null 2>&1; then
        unhealthy_services+=("web")
    fi
    
    # Check database
    if ! docker-compose exec -T postgres pg_isready -U postgres >/dev/null 2>&1; then
        unhealthy_services+=("postgres")
    fi
    
    # Check Redis
    if ! docker-compose exec -T redis redis-cli ping >/dev/null 2>&1; then
        unhealthy_services+=("redis")
    fi
    
    # Check Nginx
    if ! curl -sf http://localhost/nginx_status >/dev/null 2>&1; then
        unhealthy_services+=("nginx")
    fi
    
    # Check Sidekiq
    if ! docker-compose exec -T sidekiq pgrep -f sidekiq >/dev/null 2>&1; then
        unhealthy_services+=("sidekiq")
    fi
    
    if [[ ${#unhealthy_services[@]} -gt 0 ]]; then
        send_alert "Unhealthy services detected: ${unhealthy_services[*]}" "critical"
        return 1
    else
        success "All services are healthy"
        return 0
    fi
}

# Monitor system resources
monitor_resources() {
    log "Monitoring system resources..."
    
    local timestamp=$(date +%s)
    local metrics_file="${METRICS_DIR}/metrics_$(date +%Y%m%d).json"
    
    # Get Docker stats
    local docker_stats
    docker_stats=$(docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}" | tail -n +2)
    
    # Get system metrics
    local cpu_usage
    local memory_usage
    local disk_usage
    
    cpu_usage=$(top -bn1 | grep load | awk '{printf "%.2f%%", $(NF-2)}')
    memory_usage=$(free | grep Mem | awk '{printf "%.2f%%", $3/$2 * 100.0}')
    disk_usage=$(df -h / | awk 'NR==2{printf "%s", $5}')
    
    # Create metrics JSON
    cat > "$metrics_file" <<EOF
{
    "timestamp": $timestamp,
    "system": {
        "cpu_usage": "$cpu_usage",
        "memory_usage": "$memory_usage",
        "disk_usage": "$disk_usage"
    },
    "docker_stats": $(echo "$docker_stats" | jq -R -s -c 'split("\n") | map(select(length > 0))')
}
EOF
    
    # Check for resource alerts
    local cpu_threshold=80
    local memory_threshold=85
    local disk_threshold=90
    
    if (( $(echo "${cpu_usage%\%} > $cpu_threshold" | bc -l) )); then
        send_alert "High CPU usage detected: $cpu_usage" "warning"
    fi
    
    if (( $(echo "${memory_usage%\%} > $memory_threshold" | bc -l) )); then
        send_alert "High memory usage detected: $memory_usage" "warning"
    fi
    
    if (( $(echo "${disk_usage%\%} > $disk_threshold" | bc -l) )); then
        send_alert "High disk usage detected: $disk_usage" "critical"
    fi
}

# Check application logs for errors
check_logs() {
    log "Checking application logs for errors..."
    
    local error_count
    local log_file="/tmp/app_logs.txt"
    
    # Get logs from the last hour
    docker-compose logs --since=1h web > "$log_file" 2>&1
    
    # Count errors
    error_count=$(grep -i "error\|exception\|fatal" "$log_file" | wc -l)
    
    if [[ $error_count -gt 10 ]]; then
        send_alert "High error count in application logs: $error_count errors in the last hour" "warning"
        
        # Send sample of recent errors
        log "Recent errors:"
        tail -20 "$log_file" | grep -i "error\|exception\|fatal" | head -5
    fi
    
    # Clean up
    rm -f "$log_file"
}

# Database maintenance
database_maintenance() {
    log "Running database maintenance..."
    
    # Check database size
    local db_size
    db_size=$(docker-compose exec -T postgres psql -U postgres -d tramate_production -t -c "SELECT pg_size_pretty(pg_database_size('tramate_production'));" | xargs)
    log "Database size: $db_size"
    
    # Check for long-running queries
    local long_queries
    long_queries=$(docker-compose exec -T postgres psql -U postgres -d tramate_production -t -c "SELECT count(*) FROM pg_stat_activity WHERE state = 'active' AND now() - query_start > interval '5 minutes';" | xargs)
    
    if [[ $long_queries -gt 0 ]]; then
        warning "Found $long_queries long-running queries"
        send_alert "Database has $long_queries long-running queries" "warning"
    fi
    
    # Vacuum and analyze (weekly)
    if [[ $(date +%u) -eq 1 ]]; then  # Monday
        log "Running weekly database maintenance..."
        docker-compose exec -T postgres psql -U postgres -d tramate_production -c "VACUUM ANALYZE;"
        success "Database vacuum completed"
    fi
}

# Backup rotation
backup_rotation() {
    log "Managing backup rotation..."
    
    local backup_dir="./backups"
    
    # Keep daily backups for 7 days
    find "$backup_dir" -name "tramate_backup_*.sql" -mtime +7 -delete
    
    # Keep weekly backups for 4 weeks (keep Sunday backups)
    find "$backup_dir" -name "tramate_weekly_*.sql" -mtime +28 -delete
    
    # Create weekly backup on Sunday
    if [[ $(date +%u) -eq 7 ]]; then
        local weekly_backup="${backup_dir}/tramate_weekly_$(date +%Y%m%d).sql"
        docker-compose exec -T postgres pg_dump -U postgres tramate_production > "$weekly_backup"
        success "Weekly backup created: $weekly_backup"
    fi
}

# Security checks
security_checks() {
    log "Running security checks..."
    
    # Check for failed login attempts
    local failed_logins
    failed_logins=$(docker-compose logs web | grep -i "failed.*login\|authentication.*failed" | wc -l)
    
    if [[ $failed_logins -gt 50 ]]; then
        send_alert "High number of failed login attempts: $failed_logins" "warning"
    fi
    
    # Check for suspicious API activity
    local suspicious_requests
    suspicious_requests=$(docker-compose logs nginx | grep -E "40[0-9]|50[0-9]" | wc -l)
    
    if [[ $suspicious_requests -gt 100 ]]; then
        send_alert "High number of HTTP errors: $suspicious_requests" "warning"
    fi
}

# Clean up old logs and metrics
cleanup_old_files() {
    log "Cleaning up old files..."
    
    # Keep logs for 30 days
    find "$LOG_DIR" -name "*.log" -mtime +30 -delete
    
    # Keep metrics for 7 days
    find "$METRICS_DIR" -name "*.json" -mtime +7 -delete
    
    # Clean up Docker
    docker system prune -f --volumes
}

# Generate status report
generate_status_report() {
    local report_file="${LOG_DIR}/status_report_$(date +%Y%m%d_%H%M%S).txt"
    
    cat > "$report_file" <<EOF
Tramate Platform Status Report
Generated: $(date)
======================================

SERVICE STATUS:
$(docker-compose ps)

SYSTEM RESOURCES:
CPU Usage: $(top -bn1 | grep load | awk '{printf "%.2f%%", $(NF-2)}')
Memory Usage: $(free | grep Mem | awk '{printf "%.2f%%", $3/$2 * 100.0}')
Disk Usage: $(df -h / | awk 'NR==2{printf "%s", $5}')

DATABASE STATUS:
Size: $(docker-compose exec -T postgres psql -U postgres -d tramate_production -t -c "SELECT pg_size_pretty(pg_database_size('tramate_production'));" | xargs)
Connections: $(docker-compose exec -T postgres psql -U postgres -d tramate_production -t -c "SELECT count(*) FROM pg_stat_activity;" | xargs)

RECENT ACTIVITY:
$(docker-compose logs --tail=10 web | tail -5)

======================================
EOF
    
    log "Status report generated: $report_file"
}

# Main monitoring function
monitor() {
    log "=== Starting Tramate Monitoring ==="
    
    check_service_health
    monitor_resources
    check_logs
    database_maintenance
    backup_rotation
    security_checks
    cleanup_old_files
    
    success "=== Monitoring cycle completed ==="
}

# Continuous monitoring mode
continuous_monitor() {
    log "Starting continuous monitoring mode..."
    
    while true; do
        monitor
        sleep 300  # 5 minutes
    done
}

# Help function
show_help() {
    cat <<EOF
Tramate Monitoring Script

Usage: $0 [COMMAND]

Commands:
    monitor     Run single monitoring cycle
    continuous  Run continuous monitoring (every 5 minutes)
    health      Check service health only
    resources   Monitor system resources only
    report      Generate status report
    help        Show this help message

Examples:
    $0 monitor          # Run single monitoring cycle
    $0 continuous       # Start continuous monitoring
    $0 health          # Quick health check
EOF
}

# Main execution
case "${1:-monitor}" in
    "monitor")
        monitor
        ;;
    "continuous")
        continuous_monitor
        ;;
    "health")
        check_service_health
        ;;
    "resources")
        monitor_resources
        ;;
    "report")
        generate_status_report
        ;;
    "help"|"-h"|"--help")
        show_help
        ;;
    *)
        error "Unknown command: $1"
        show_help
        exit 1
        ;;
esac
