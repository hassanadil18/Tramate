#!/bin/bash

# Tramate Backup and Restore Script
# Comprehensive backup and restore functionality for production data

set -euo pipefail

# Configuration
PROJECT_NAME="tramate"
BACKUP_DIR="./backups"
S3_BUCKET=""  # Set your S3 bucket for remote backups
LOG_FILE="./logs/backup.log"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Create directories
mkdir -p "$BACKUP_DIR" "./logs"

# Logging
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_FILE"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1" | tee -a "$LOG_FILE"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a "$LOG_FILE"
}

# Full backup (database + volumes)
full_backup() {
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_name="tramate_full_${timestamp}"
    local backup_path="${BACKUP_DIR}/${backup_name}"
    
    log "Starting full backup: $backup_name"
    
    # Create backup directory
    mkdir -p "$backup_path"
    
    # Backup database
    log "Backing up database..."
    docker-compose exec -T postgres pg_dump -U postgres \
        --clean --create --if-exists \
        tramate_production > "${backup_path}/database.sql"
    
    # Backup Redis data
    log "Backing up Redis data..."
    docker-compose exec -T redis redis-cli --rdb - > "${backup_path}/redis.rdb"
    
    # Backup application data volumes
    log "Backing up application volumes..."
    docker run --rm \
        --volumes-from "$(docker-compose ps -q web)" \
        -v "${PWD}/${backup_path}:/backup" \
        alpine tar czf /backup/app_data.tar.gz /app/storage /app/public/uploads 2>/dev/null || true
    
    # Backup configuration files
    log "Backing up configuration..."
    tar czf "${backup_path}/config.tar.gz" \
        .env docker-compose.yml nginx/ scripts/ 2>/dev/null || true
    
    # Create backup metadata
    cat > "${backup_path}/metadata.json" <<EOF
{
    "backup_name": "$backup_name",
    "timestamp": "$timestamp",
    "type": "full",
    "services": ["postgres", "redis", "web"],
    "created_at": "$(date -Iseconds)",
    "size": "$(du -sh "$backup_path" | cut -f1)"
}
EOF
    
    # Compress the entire backup
    log "Compressing backup..."
    tar czf "${backup_path}.tar.gz" -C "$BACKUP_DIR" "$backup_name"
    rm -rf "$backup_path"
    
    success "Full backup completed: ${backup_path}.tar.gz"
    
    # Upload to S3 if configured
    if [[ -n "$S3_BUCKET" ]]; then
        upload_to_s3 "${backup_path}.tar.gz"
    fi
    
    echo "${backup_path}.tar.gz"
}

# Database-only backup
database_backup() {
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_file="${BACKUP_DIR}/tramate_db_${timestamp}.sql"
    
    log "Starting database backup..."
    
    docker-compose exec -T postgres pg_dump -U postgres \
        --clean --create --if-exists \
        tramate_production > "$backup_file"
    
    # Compress the backup
    gzip "$backup_file"
    backup_file="${backup_file}.gz"
    
    success "Database backup completed: $backup_file"
    
    # Upload to S3 if configured
    if [[ -n "$S3_BUCKET" ]]; then
        upload_to_s3 "$backup_file"
    fi
    
    echo "$backup_file"
}

# Upload backup to S3
upload_to_s3() {
    local backup_file="$1"
    
    if ! command -v aws &> /dev/null; then
        warning "AWS CLI not found. Skipping S3 upload."
        return
    fi
    
    log "Uploading backup to S3..."
    
    local s3_key="tramate/backups/$(basename "$backup_file")"
    
    if aws s3 cp "$backup_file" "s3://${S3_BUCKET}/${s3_key}"; then
        success "Backup uploaded to S3: s3://${S3_BUCKET}/${s3_key}"
    else
        error "Failed to upload backup to S3"
    fi
}

# List available backups
list_backups() {
    log "Available local backups:"
    
    if [[ ! -d "$BACKUP_DIR" ]] || [[ -z "$(ls -A "$BACKUP_DIR" 2>/dev/null)" ]]; then
        warning "No backups found in $BACKUP_DIR"
        return
    fi
    
    echo "Local backups:"
    ls -lah "$BACKUP_DIR"/*.tar.gz "$BACKUP_DIR"/*.sql.gz 2>/dev/null | \
        awk '{print $9, $5, $6, $7, $8}' | \
        sort -k3,4
    
    # List S3 backups if configured
    if [[ -n "$S3_BUCKET" ]] && command -v aws &> /dev/null; then
        echo -e "\nS3 backups:"
        aws s3 ls "s3://${S3_BUCKET}/tramate/backups/" --human-readable
    fi
}

# Restore from backup
restore_backup() {
    local backup_file="$1"
    
    if [[ ! -f "$backup_file" ]]; then
        error "Backup file not found: $backup_file"
        exit 1
    fi
    
    log "Starting restore from backup: $backup_file"
    
    # Ask for confirmation
    echo -e "${YELLOW}WARNING: This will replace current data with backup data.${NC}"
    read -p "Are you sure you want to continue? (yes/no): " -r
    if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
        log "Restore cancelled by user"
        exit 0
    fi
    
    # Stop services
    log "Stopping services..."
    docker-compose down
    
    # Determine backup type
    if [[ "$backup_file" == *.tar.gz ]]; then
        restore_full_backup "$backup_file"
    elif [[ "$backup_file" == *.sql.gz ]] || [[ "$backup_file" == *.sql ]]; then
        restore_database_backup "$backup_file"
    else
        error "Unsupported backup format: $backup_file"
        exit 1
    fi
    
    # Start services
    log "Starting services..."
    docker-compose up -d
    
    # Wait for services to be ready
    sleep 30
    
    # Verify restore
    if curl -sf http://localhost/health >/dev/null 2>&1; then
        success "Restore completed successfully"
    else
        error "Restore may have issues. Please check service health."
    fi
}

# Restore full backup
restore_full_backup() {
    local backup_file="$1"
    local extract_dir="${BACKUP_DIR}/restore_temp"
    
    log "Extracting full backup..."
    
    # Extract backup
    mkdir -p "$extract_dir"
    tar xzf "$backup_file" -C "$extract_dir"
    
    local backup_name
    backup_name=$(ls "$extract_dir" | head -1)
    local backup_path="${extract_dir}/${backup_name}"
    
    # Restore database
    if [[ -f "${backup_path}/database.sql" ]]; then
        log "Restoring database..."
        docker-compose up -d postgres
        sleep 10
        cat "${backup_path}/database.sql" | docker-compose exec -T postgres psql -U postgres
    fi
    
    # Restore Redis
    if [[ -f "${backup_path}/redis.rdb" ]]; then
        log "Restoring Redis data..."
        docker-compose up -d redis
        sleep 5
        docker-compose exec -T redis redis-cli FLUSHALL
        cat "${backup_path}/redis.rdb" | docker-compose exec -T redis redis-cli --pipe
    fi
    
    # Restore application data
    if [[ -f "${backup_path}/app_data.tar.gz" ]]; then
        log "Restoring application data..."
        docker run --rm \
            --volumes-from "$(docker-compose ps -q web)" \
            -v "${PWD}/${backup_path}:/backup" \
            alpine tar xzf /backup/app_data.tar.gz -C /
    fi
    
    # Clean up
    rm -rf "$extract_dir"
    
    success "Full backup restored"
}

# Restore database backup
restore_database_backup() {
    local backup_file="$1"
    
    log "Restoring database backup..."
    
    # Start only database
    docker-compose up -d postgres
    sleep 10
    
    # Restore database
    if [[ "$backup_file" == *.gz ]]; then
        zcat "$backup_file" | docker-compose exec -T postgres psql -U postgres
    else
        cat "$backup_file" | docker-compose exec -T postgres psql -U postgres
    fi
    
    success "Database backup restored"
}

# Automated backup with rotation
automated_backup() {
    log "Starting automated backup..."
    
    # Daily database backup
    local db_backup
    db_backup=$(database_backup)
    
    # Weekly full backup (on Sunday)
    if [[ $(date +%u) -eq 7 ]]; then
        log "Creating weekly full backup..."
        full_backup
    fi
    
    # Cleanup old backups
    cleanup_old_backups
    
    success "Automated backup completed"
}

# Cleanup old backups
cleanup_old_backups() {
    log "Cleaning up old backups..."
    
    # Keep daily database backups for 7 days
    find "$BACKUP_DIR" -name "tramate_db_*.sql.gz" -mtime +7 -delete
    
    # Keep full backups for 30 days
    find "$BACKUP_DIR" -name "tramate_full_*.tar.gz" -mtime +30 -delete
    
    success "Backup cleanup completed"
}

# Verify backup integrity
verify_backup() {
    local backup_file="$1"
    
    log "Verifying backup integrity: $backup_file"
    
    if [[ ! -f "$backup_file" ]]; then
        error "Backup file not found: $backup_file"
        return 1
    fi
    
    # Check file integrity
    if [[ "$backup_file" == *.tar.gz ]]; then
        if tar tzf "$backup_file" >/dev/null 2>&1; then
            success "Backup archive integrity verified"
        else
            error "Backup archive is corrupted"
            return 1
        fi
    elif [[ "$backup_file" == *.sql.gz ]]; then
        if zcat "$backup_file" | head -10 | grep -q "PostgreSQL database dump"; then
            success "Database backup integrity verified"
        else
            error "Database backup is corrupted"
            return 1
        fi
    fi
    
    return 0
}

# Show help
show_help() {
    cat <<EOF
Tramate Backup and Restore Script

Usage: $0 [COMMAND] [OPTIONS]

Commands:
    full-backup         Create full backup (database + volumes)
    db-backup          Create database-only backup
    list               List available backups
    restore FILE       Restore from backup file
    automated          Run automated backup with rotation
    verify FILE        Verify backup integrity
    help              Show this help message

Examples:
    $0 full-backup                    # Create full backup
    $0 db-backup                      # Create database backup
    $0 restore backup.tar.gz          # Restore from backup
    $0 list                          # List all backups
    $0 verify backup.tar.gz          # Verify backup

Configuration:
    Set S3_BUCKET environment variable for remote backups
EOF
}

# Main execution
case "${1:-help}" in
    "full-backup")
        full_backup
        ;;
    "db-backup")
        database_backup
        ;;
    "list")
        list_backups
        ;;
    "restore")
        if [[ -z "${2:-}" ]]; then
            error "Please specify backup file to restore"
            exit 1
        fi
        restore_backup "$2"
        ;;
    "automated")
        automated_backup
        ;;
    "verify")
        if [[ -z "${2:-}" ]]; then
            error "Please specify backup file to verify"
            exit 1
        fi
        verify_backup "$2"
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
