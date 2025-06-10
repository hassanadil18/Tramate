#!/bin/bash

# Tramate Production Setup Script
# Complete setup automation for production deployment

set -euo pipefail

# Configuration
PROJECT_NAME="tramate"
PROJECT_DIR="/opt/tramate"
USER="tramate"
DOMAIN=""  # Set your domain name

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Check if running as root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        log "Running as root user"
    else
        error "This script must be run as root"
        exit 1
    fi
}

# Update system
update_system() {
    log "Updating system packages..."
    apt-get update
    apt-get upgrade -y
    apt-get install -y curl wget git vim htop unzip software-properties-common
    success "System updated"
}

# Install Docker
install_docker() {
    log "Installing Docker..."
    
    # Remove old versions
    apt-get remove -y docker docker-engine docker.io containerd runc || true
    
    # Install dependencies
    apt-get install -y ca-certificates curl gnupg lsb-release
    
    # Add Docker GPG key
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    
    # Add Docker repository
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    # Install Docker
    apt-get update
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
    
    # Start and enable Docker
    systemctl start docker
    systemctl enable docker
    
    success "Docker installed"
}

# Install Docker Compose
install_docker_compose() {
    log "Installing Docker Compose..."
    
    local version="2.24.0"
    curl -L "https://github.com/docker/compose/releases/download/v${version}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    
    success "Docker Compose installed"
}

# Create application user
create_user() {
    log "Creating application user..."
    
    if ! id "$USER" &>/dev/null; then
        useradd -m -s /bin/bash "$USER"
        usermod -aG docker "$USER"
        success "User $USER created"
    else
        warning "User $USER already exists"
    fi
}

# Setup project directory
setup_project_directory() {
    log "Setting up project directory..."
    
    mkdir -p "$PROJECT_DIR"
    chown -R "$USER:$USER" "$PROJECT_DIR"
    
    # Create necessary subdirectories
    sudo -u "$USER" mkdir -p "$PROJECT_DIR"/{logs,backups,scripts,ssl}
    
    success "Project directory setup complete"
}

# Setup firewall
setup_firewall() {
    log "Configuring firewall..."
    
    # Install UFW
    apt-get install -y ufw
    
    # Default policies
    ufw default deny incoming
    ufw default allow outgoing
    
    # Allow SSH
    ufw allow ssh
    
    # Allow HTTP and HTTPS
    ufw allow 80/tcp
    ufw allow 443/tcp
    
    # Allow Docker Swarm (if needed)
    # ufw allow 2376/tcp
    # ufw allow 2377/tcp
    # ufw allow 7946/tcp
    # ufw allow 7946/udp
    # ufw allow 4789/udp
    
    # Enable firewall
    ufw --force enable
    
    success "Firewall configured"
}

# Setup SSL with Let's Encrypt
setup_ssl() {
    if [[ -z "$DOMAIN" ]]; then
        warning "Domain not set, skipping SSL setup"
        return
    fi
    
    log "Setting up SSL with Let's Encrypt..."
    
    # Install Certbot
    apt-get install -y certbot python3-certbot-nginx
    
    # Get certificate
    certbot --nginx -d "$DOMAIN" --non-interactive --agree-tos --email "admin@${DOMAIN}"
    
    # Setup auto-renewal
    (crontab -l 2>/dev/null; echo "0 12 * * * /usr/bin/certbot renew --quiet") | crontab -
    
    success "SSL configured for $DOMAIN"
}

# Setup monitoring
setup_monitoring() {
    log "Setting up monitoring tools..."
    
    # Install Node Exporter
    local node_exporter_version="1.7.0"
    cd /tmp
    wget "https://github.com/prometheus/node_exporter/releases/download/v${node_exporter_version}/node_exporter-${node_exporter_version}.linux-amd64.tar.gz"
    tar xvfz "node_exporter-${node_exporter_version}.linux-amd64.tar.gz"
    cp "node_exporter-${node_exporter_version}.linux-amd64/node_exporter" /usr/local/bin/
    rm -rf "node_exporter-${node_exporter_version}.linux-amd64"*
    
    # Create node_exporter service
    cat > /etc/systemd/system/node_exporter.service <<EOF
[Unit]
Description=Node Exporter
Wants=network-online.target
After=network-online.target

[Service]
User=nobody
Group=nobody
Type=simple
ExecStart=/usr/local/bin/node_exporter

[Install]
WantedBy=multi-user.target
EOF
    
    systemctl daemon-reload
    systemctl enable node_exporter
    systemctl start node_exporter
    
    success "Monitoring setup complete"
}

# Setup log rotation
setup_log_rotation() {
    log "Setting up log rotation..."
    
    cat > /etc/logrotate.d/tramate <<EOF
${PROJECT_DIR}/logs/*.log {
    daily
    missingok
    rotate 30
    compress
    delaycompress
    notifempty
    copytruncate
    su $USER $USER
}
EOF
    
    success "Log rotation configured"
}

# Setup backup cron
setup_backup_cron() {
    log "Setting up automated backups..."
    
    # Add backup cron job for the application user
    sudo -u "$USER" bash -c "(crontab -l 2>/dev/null; echo '0 2 * * * cd $PROJECT_DIR && ./scripts/backup.sh automated') | crontab -"
    
    success "Backup cron job configured"
}

# Setup system limits
setup_system_limits() {
    log "Configuring system limits..."
    
    cat >> /etc/security/limits.conf <<EOF
# Tramate application limits
$USER soft nofile 65536
$USER hard nofile 65536
$USER soft nproc 32768
$USER hard nproc 32768
EOF
    
    # Docker daemon configuration
    mkdir -p /etc/docker
    cat > /etc/docker/daemon.json <<EOF
{
    "log-driver": "json-file",
    "log-opts": {
        "max-size": "10m",
        "max-file": "3"
    },
    "storage-driver": "overlay2"
}
EOF
    
    systemctl restart docker
    
    success "System limits configured"
}

# Clone repository
clone_repository() {
    log "Cloning repository..."
    
    if [[ ! -d "$PROJECT_DIR/.git" ]]; then
        sudo -u "$USER" git clone https://github.com/yourusername/tramate.git "$PROJECT_DIR"
    else
        cd "$PROJECT_DIR"
        sudo -u "$USER" git pull origin main
    fi
    
    success "Repository cloned/updated"
}

# Setup environment
setup_environment() {
    log "Setting up environment configuration..."
    
    if [[ ! -f "$PROJECT_DIR/.env" ]]; then
        cp "$PROJECT_DIR/.env.example" "$PROJECT_DIR/.env"
        chown "$USER:$USER" "$PROJECT_DIR/.env"
        chmod 600 "$PROJECT_DIR/.env"
        
        warning "Please edit $PROJECT_DIR/.env with your configuration"
    fi
    
    success "Environment setup complete"
}

# Make scripts executable
setup_scripts() {
    log "Setting up scripts..."
    
    chmod +x "$PROJECT_DIR"/scripts/*.sh
    chown -R "$USER:$USER" "$PROJECT_DIR/scripts"
    
    success "Scripts configured"
}

# Show completion message
show_completion() {
    success "=== Tramate Production Setup Complete ==="
    cat <<EOF

Next steps:
1. Edit the environment file: $PROJECT_DIR/.env
2. Configure your domain settings if using SSL
3. Deploy the application: cd $PROJECT_DIR && ./scripts/deploy.sh
4. Setup monitoring: docker-compose -f docker-compose.monitoring.yml up -d

Important directories:
- Project: $PROJECT_DIR
- Logs: $PROJECT_DIR/logs
- Backups: $PROJECT_DIR/backups
- Scripts: $PROJECT_DIR/scripts

Services will be available at:
- Application: http://localhost (or https://$DOMAIN if SSL configured)
- Monitoring: http://localhost:3000 (Grafana)
- Logs: http://localhost:5601 (Kibana)

For support, check the documentation or logs in $PROJECT_DIR/logs/
EOF
}

# Main setup function
main() {
    log "=== Starting Tramate Production Setup ==="
    
    check_root
    update_system
    install_docker
    install_docker_compose
    create_user
    setup_project_directory
    setup_firewall
    setup_ssl
    setup_monitoring
    setup_log_rotation
    setup_backup_cron
    setup_system_limits
    clone_repository
    setup_environment
    setup_scripts
    
    show_completion
}

# Run main function
main "$@"
