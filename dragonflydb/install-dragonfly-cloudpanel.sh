#!/bin/bash

# DragonflyDB Installer for CloudPanel
# Version: 1.0
# Author: CloudPanel Community
# Description: Automated installer to replace Redis with DragonflyDB on CloudPanel

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Log file
LOG_FILE="/var/log/dragonfly-installer.log"

# Functions
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
    log "SUCCESS: $1"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
    log "ERROR: $1"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
    log "INFO: $1"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
    log "WARNING: $1"
}

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "This script must be run as root!"
        exit 1
    fi
}

# Check OS compatibility
check_os() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        OS=$ID
        VER=$VERSION_ID
    else
        print_error "Cannot determine OS version"
        exit 1
    fi

    case $OS in
        ubuntu)
            if [[ "$VER" != "22.04" && "$VER" != "24.04" ]]; then
                print_error "Ubuntu $VER is not supported. Please use Ubuntu 22.04 or 24.04"
                exit 1
            fi
            ;;
        debian)
            if [[ "$VER" != "11" && "$VER" != "12" ]]; then
                print_error "Debian $VER is not supported. Please use Debian 11 or 12"
                exit 1
            fi
            ;;
        *)
            print_error "OS $OS is not supported. Please use Ubuntu 22.04/24.04 or Debian 11/12"
            exit 1
            ;;
    esac
    
    print_success "OS compatibility check passed: $OS $VER"
}

# Check CloudPanel installation
check_cloudpanel() {
    if [[ ! -d "/home/clp" ]]; then
        print_error "CloudPanel installation not found!"
        echo "Please install CloudPanel first: https://www.cloudpanel.io/docs/v2/getting-started/installation/"
        exit 1
    fi
    
    print_success "CloudPanel installation detected"
}

# Get system architecture
get_architecture() {
    ARCH=$(uname -m)
    case $ARCH in
        x86_64)
            DRAGONFLY_ARCH="x86_64"
            ;;
        aarch64)
            DRAGONFLY_ARCH="aarch64"
            ;;
        *)
            print_error "Unsupported architecture: $ARCH"
            exit 1
            ;;
    esac
    
    print_success "Architecture detected: $ARCH"
}

# Calculate optimal memory settings
calculate_memory() {
    TOTAL_MEM_KB=$(grep MemTotal /proc/meminfo | awk '{print $2}')
    TOTAL_MEM_GB=$((TOTAL_MEM_KB / 1024 / 1024))
    
    # Use 25% of total memory for DragonflyDB
    if [[ $TOTAL_MEM_GB -le 4 ]]; then
        DRAGONFLY_MEM="1gb"
    elif [[ $TOTAL_MEM_GB -le 8 ]]; then
        DRAGONFLY_MEM="2gb"
    elif [[ $TOTAL_MEM_GB -le 16 ]]; then
        DRAGONFLY_MEM="4gb"
    elif [[ $TOTAL_MEM_GB -le 32 ]]; then
        DRAGONFLY_MEM="8gb"
    else
        DRAGONFLY_MEM="16gb"
    fi
    
    print_info "Total system memory: ${TOTAL_MEM_GB}GB"
    print_info "DragonflyDB will use: $DRAGONFLY_MEM"
}

# Check if Redis is running and has data
check_redis() {
    if systemctl is-active --quiet redis-server; then
        print_info "Redis is currently running"
        
        # Check if Redis has data
        if command -v redis-cli &> /dev/null; then
            REDIS_KEYS=$(redis-cli DBSIZE 2>/dev/null | awk '{print $2}' || echo "0")
            if [[ "$REDIS_KEYS" -gt 0 ]]; then
                print_warning "Redis contains $REDIS_KEYS keys"
                read -p "Do you want to backup Redis data? (y/n): " -n 1 -r
                echo
                if [[ $REPLY =~ ^[Yy]$ ]]; then
                    print_info "Creating Redis backup..."
                    redis-cli BGSAVE
                    sleep 3
                    print_success "Redis backup created"
                fi
            else
                print_info "Redis is empty (no data to backup)"
            fi
        fi
        
        return 0
    else
        print_info "Redis is not running"
        return 1
    fi
}

# Stop and disable Redis
stop_redis() {
    print_info "Stopping Redis service..."
    
    if systemctl is-active --quiet redis-server; then
        systemctl stop redis-server || print_warning "Failed to stop Redis service"
    fi
    
    if systemctl is-enabled --quiet redis-server; then
        systemctl disable redis-server &>/dev/null || print_warning "Failed to disable Redis service"
    fi
    
    print_success "Redis service stopped and disabled"
}

# Download and install DragonflyDB
install_dragonfly() {
    print_info "Downloading DragonflyDB for $DRAGONFLY_ARCH..."
    
    cd /tmp
    DOWNLOAD_URL="https://github.com/dragonflydb/dragonfly/releases/latest/download/dragonfly-${DRAGONFLY_ARCH}.tar.gz"
    
    # Download with retry
    for i in {1..3}; do
        if wget -q --show-progress "$DOWNLOAD_URL" -O "dragonfly-${DRAGONFLY_ARCH}.tar.gz"; then
            print_success "Download completed"
            break
        else
            print_warning "Download attempt $i failed"
            if [[ $i -eq 3 ]]; then
                print_error "Failed to download DragonflyDB after 3 attempts"
                exit 1
            fi
            sleep 5
        fi
    done
    
    # Extract and install
    print_info "Installing DragonflyDB..."
    tar -xzf "dragonfly-${DRAGONFLY_ARCH}.tar.gz"
    
    # Backup existing dragonfly if exists
    if [[ -f /usr/local/bin/dragonfly ]]; then
        mv /usr/local/bin/dragonfly "/usr/local/bin/dragonfly.backup.$(date +%Y%m%d%H%M%S)"
    fi
    
    mv "dragonfly-${DRAGONFLY_ARCH}" /usr/local/bin/dragonfly
    chmod +x /usr/local/bin/dragonfly
    rm -f "dragonfly-${DRAGONFLY_ARCH}.tar.gz"
    
    print_success "DragonflyDB installed successfully"
}

# Create DragonflyDB user and directories
setup_user_and_dirs() {
    print_info "Creating DragonflyDB user and directories..."
    
    # Create user if not exists
    if ! id -u dragonfly &>/dev/null; then
        useradd -r -s /bin/false -d /var/lib/dragonfly -m dragonfly
    fi
    
    # Create directories
    mkdir -p /etc/dragonfly /var/log/dragonfly /var/lib/dragonfly
    chown dragonfly:dragonfly /var/log/dragonfly /var/lib/dragonfly
    chmod 755 /etc/dragonfly /var/log/dragonfly /var/lib/dragonfly
    
    print_success "User and directories created"
}

# Create DragonflyDB configuration
create_config() {
    print_info "Creating DragonflyDB configuration..."
    
    cat > /etc/dragonfly/dragonfly.conf << EOF
# DragonflyDB Configuration
# Generated by CloudPanel DragonflyDB Installer
# Date: $(date)

--bind=127.0.0.1
--port=6379
--dir=/var/lib/dragonfly
--logtostderr
--maxmemory=$DRAGONFLY_MEM
--dbfilename=dump
EOF
    
    chmod 644 /etc/dragonfly/dragonfly.conf
    print_success "Configuration created with memory limit: $DRAGONFLY_MEM"
}

# Create systemd service
create_service() {
    print_info "Creating systemd service..."
    
    cat > /etc/systemd/system/dragonfly.service << 'EOF'
[Unit]
Description=DragonflyDB In-Memory Data Store
Documentation=https://www.dragonflydb.io/docs
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/dragonfly --flagfile=/etc/dragonfly/dragonfly.conf
ExecStop=/bin/kill -TERM $MAINPID
Restart=always
RestartSec=3
User=dragonfly
Group=dragonfly

# Security settings
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=/var/lib/dragonfly /var/log/dragonfly
ProtectKernelTunables=true
ProtectKernelModules=true
ProtectControlGroups=true
RestrictRealtime=true
RestrictNamespaces=true
RestrictSUIDSGID=true
PrivateDevices=true
ProtectHostname=true
ProtectClock=true
ProtectKernelLogs=true
LockPersonality=true

# Resource limits
LimitNOFILE=65535
LimitMEMLOCK=infinity

# Performance settings
CPUSchedulingPolicy=batch
Nice=-5

# OOM settings
OOMScoreAdjust=-900

[Install]
WantedBy=multi-user.target
EOF
    
    chmod 644 /etc/systemd/system/dragonfly.service
    print_success "Systemd service created"
}

# Create Redis compatibility layer
create_compatibility() {
    print_info "Creating Redis compatibility layer..."
    
    # Remove old symlinks if exist
    rm -f /etc/systemd/system/redis-server.service /etc/systemd/system/redis.service
    
    # Create service symlinks
    ln -sf /etc/systemd/system/dragonfly.service /etc/systemd/system/redis-server.service
    ln -sf /etc/systemd/system/dragonfly.service /etc/systemd/system/redis.service
    
    # Create Redis CLI symlink
    if [[ -f /usr/bin/redis-cli ]]; then
        ln -sf /usr/bin/redis-cli /usr/bin/dragonfly-cli
    fi
    
    # Create Redis server wrapper
    cat > /usr/local/bin/redis-server << 'EOF'
#!/bin/bash
# Redis compatibility wrapper for DragonflyDB
exec /usr/local/bin/dragonfly "$@"
EOF
    
    chmod +x /usr/local/bin/redis-server
    
    print_success "Redis compatibility layer created"
}

# Start DragonflyDB service
start_dragonfly() {
    print_info "Starting DragonflyDB service..."
    
    systemctl daemon-reload
    systemctl enable dragonfly &>/dev/null
    
    if systemctl start dragonfly; then
        print_success "DragonflyDB service started"
    else
        print_error "Failed to start DragonflyDB service"
        echo "Check logs with: journalctl -xeu dragonfly.service"
        exit 1
    fi
}

# Test DragonflyDB connection
test_connection() {
    print_info "Testing DragonflyDB connection..."
    
    # Wait for service to be ready
    sleep 2
    
    if command -v redis-cli &> /dev/null; then
        if redis-cli ping &>/dev/null; then
            print_success "DragonflyDB is responding to commands"
            
            # Get version info
            VERSION=$(redis-cli INFO server | grep dragonfly_version | cut -d: -f2 | tr -d '\r')
            if [[ -n "$VERSION" ]]; then
                print_success "Running DragonflyDB version: $VERSION"
            fi
        else
            print_error "DragonflyDB is not responding"
            return 1
        fi
    else
        print_warning "redis-cli not found, skipping connection test"
    fi
    
    return 0
}

# Test PHP connection
test_php_connection() {
    print_info "Testing PHP Redis extension..."
    
    PHP_TEST=$(mktemp)
    cat > "$PHP_TEST" << 'EOF'
<?php
try {
    $redis = new Redis();
    $redis->connect('127.0.0.1', 6379);
    echo "SUCCESS";
} catch (Exception $e) {
    echo "FAILED: " . $e->getMessage();
}
EOF
    
    RESULT=$(php "$PHP_TEST" 2>&1)
    rm -f "$PHP_TEST"
    
    if [[ "$RESULT" == "SUCCESS" ]]; then
        print_success "PHP can connect to DragonflyDB"
    else
        print_warning "PHP Redis test failed: $RESULT"
        print_info "You may need to install php-redis extension"
    fi
}

# Show summary
show_summary() {
    echo
    echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}       DragonflyDB Installation Completed Successfully!        ${NC}"
    echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
    echo
    echo -e "${BLUE}Service Status:${NC}"
    echo -e "  DragonflyDB:     $(systemctl is-active dragonfly)"
    echo -e "  Redis Alias:     $(systemctl is-active redis-server)"
    echo
    echo -e "${BLUE}Configuration:${NC}"
    echo -e "  Config File:     /etc/dragonfly/dragonfly.conf"
    echo -e "  Memory Limit:    $DRAGONFLY_MEM"
    echo -e "  Data Directory:  /var/lib/dragonfly"
    echo -e "  Port:            6379"
    echo
    echo -e "${BLUE}Useful Commands:${NC}"
    echo -e "  Status:          systemctl status dragonfly"
    echo -e "  Logs:            journalctl -xeu dragonfly -f"
    echo -e "  Connect:         redis-cli"
    echo -e "  Info:            redis-cli INFO server"
    echo
    echo -e "${YELLOW}Note:${NC} CloudPanel should now show Redis as 'Active' in the Services section."
    echo
}

# Main installation flow
main() {
    echo
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}        DragonflyDB Installer for CloudPanel v1.0              ${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    echo
    
    # Create log file
    mkdir -p "$(dirname "$LOG_FILE")"
    echo "Installation started at $(date)" > "$LOG_FILE"
    
    # Pre-flight checks
    check_root
    check_os
    check_cloudpanel
    get_architecture
    calculate_memory
    
    # Confirm installation
    echo
    echo -e "${YELLOW}This script will:${NC}"
    echo "  • Stop and disable Redis (if running)"
    echo "  • Install DragonflyDB as a Redis replacement"
    echo "  • Configure DragonflyDB with ${DRAGONFLY_MEM} memory"
    echo "  • Create Redis compatibility aliases"
    echo
    read -p "Do you want to continue? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "Installation cancelled"
        exit 0
    fi
    
    # Installation steps
    echo
    if check_redis; then
        stop_redis
    fi
    
    install_dragonfly
    setup_user_and_dirs
    create_config
    create_service
    create_compatibility
    start_dragonfly
    
    # Post-installation tests
    echo
    test_connection
    test_php_connection
    
    # Show summary
    show_summary
    
    log "Installation completed successfully"
}

# Run main function
main "$@"