# How to Replace Redis with DragonflyDB on CloudPanel

This guide explains how to properly install DragonflyDB and configure it as a drop-in replacement for Redis on CloudPanel servers.

## Prerequisites

- CloudPanel installed on Ubuntu 22.04/24.04 or Debian 11/12
- Root access to the server
- Basic command line knowledge

## Step 1: Check System Architecture

First, determine your server's architecture:

```bash
uname -m
```

- If output is `x86_64`: You have Intel/AMD architecture
- If output is `aarch64`: You have ARM64 architecture

## Step 2: Stop and Disable Redis

Before installing DragonflyDB, we need to stop the existing Redis service:

```bash
# Check Redis status
systemctl status redis-server

# Create a backup of Redis data (if needed)
redis-cli BGSAVE
sleep 2

# Stop and disable Redis
systemctl stop redis-server
systemctl disable redis-server
```

## Step 3: Install DragonflyDB

### For x86_64 Architecture:

```bash
# Download DragonflyDB
cd /root
wget https://github.com/dragonflydb/dragonfly/releases/latest/download/dragonfly-x86_64.tar.gz

# Extract and install
tar -xzf dragonfly-x86_64.tar.gz
mv dragonfly-x86_64 /usr/local/bin/dragonfly
chmod +x /usr/local/bin/dragonfly
rm dragonfly-x86_64.tar.gz
```

### For ARM64 Architecture:

```bash
# Download DragonflyDB
cd /root
wget https://github.com/dragonflydb/dragonfly/releases/latest/download/dragonfly-aarch64.tar.gz

# Extract and install
tar -xzf dragonfly-aarch64.tar.gz
mv dragonfly-aarch64 /usr/local/bin/dragonfly
chmod +x /usr/local/bin/dragonfly
rm dragonfly-aarch64.tar.gz
```

## Step 4: Create DragonflyDB User and Directories

```bash
# Create system user
useradd -r -s /bin/false -d /var/lib/dragonfly -m dragonfly

# Create directories
mkdir -p /etc/dragonfly /var/log/dragonfly
chown dragonfly:dragonfly /var/log/dragonfly /var/lib/dragonfly
```

## Step 5: Create DragonflyDB Configuration

Create the configuration file `/etc/dragonfly/dragonfly.conf`:

```bash
cat > /etc/dragonfly/dragonfly.conf << 'EOF'
# DragonflyDB Configuration
# Using flagfile format (--flag=value)

--bind=127.0.0.1
--port=6379
--dir=/var/lib/dragonfly
--logtostderr
--maxmemory=4gb
--dbfilename=dump
EOF
```

**Note**: Adjust `--maxmemory` based on your server's RAM. A good rule is 25-30% of total RAM.

## Step 6: Create Systemd Service

Create the service file `/etc/systemd/system/dragonfly.service`:

```bash
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
```

## Step 7: Create Redis Compatibility Layer

To ensure CloudPanel recognizes DragonflyDB as Redis:

```bash
# Create Redis service symlink
ln -sf /etc/systemd/system/dragonfly.service /etc/systemd/system/redis-server.service
ln -sf /etc/systemd/system/dragonfly.service /etc/systemd/system/redis.service

# Create Redis CLI symlink
ln -sf /usr/bin/redis-cli /usr/bin/dragonfly-cli

# Create Redis server wrapper
cat > /usr/local/bin/redis-server << 'EOF'
#!/bin/bash
# Redis compatibility wrapper for DragonflyDB
exec /usr/local/bin/dragonfly "$@"
EOF

chmod +x /usr/local/bin/redis-server
```

## Step 8: Start and Enable DragonflyDB

```bash
# Reload systemd
systemctl daemon-reload

# Enable and start DragonflyDB
systemctl enable dragonfly
systemctl start dragonfly

# Verify status
systemctl status dragonfly
systemctl status redis-server  # Should show the same status
```

## Step 9: Test the Installation

```bash
# Test connection
redis-cli ping
# Should return: PONG

# Check server info
redis-cli INFO server | grep dragonfly_version
# Should show: dragonfly_version:df-v1.31.0 (or newer)

# Test basic operations
redis-cli SET test "Hello from DragonflyDB"
redis-cli GET test
redis-cli DEL test
```

## Step 10: Verify CloudPanel Integration

Create a PHP test script to verify CloudPanel can connect:

```bash
cat > /tmp/test-redis.php << 'EOF'
<?php
try {
    $redis = new Redis();
    $redis->connect('127.0.0.1', 6379);
    echo "Connected to Redis/DragonflyDB\n";
    echo "PING: " . $redis->ping() . "\n";
    $redis->set('test_key', 'CloudPanel works with DragonflyDB!');
    echo "Value: " . $redis->get('test_key') . "\n";
    $redis->del('test_key');
    echo "✅ All tests passed!\n";
} catch (Exception $e) {
    echo "❌ Error: " . $e->getMessage() . "\n";
}
EOF

php /tmp/test-redis.php
rm /tmp/test-redis.php
```

## Troubleshooting

### If CloudPanel shows Redis as stopped:

1. Check if the redis-server service is active:
```bash
systemctl is-active redis-server
```

2. Clear CloudPanel cache and reload the page

3. Restart PHP-FPM:
```bash
systemctl restart php*-fpm
```

### If DragonflyDB fails to start:

1. Check logs:
```bash
journalctl -xeu dragonfly.service -n 50
```

2. Verify port 6379 is not in use:
```bash
ss -tlnp | grep 6379
```

3. Check configuration syntax:
```bash
/usr/local/bin/dragonfly --flagfile=/etc/dragonfly/dragonfly.conf --dry-run
```

## Performance Tuning

### Memory Configuration

For optimal performance, adjust memory settings based on your server:

- **8GB RAM**: Set `--maxmemory=2gb`
- **16GB RAM**: Set `--maxmemory=4gb`
- **32GB RAM**: Set `--maxmemory=10gb`
- **64GB+ RAM**: Set `--maxmemory=20gb` or more

### Additional Optimizations

Edit `/etc/dragonfly/dragonfly.conf` and add:

```bash
# For high-traffic sites
--pipeline_buffer_limit=8mb
--tcp_nodelay

# For sites with many connections
--max_clients=10000
```

## Benefits of DragonflyDB over Redis

- **25x faster** than Redis on modern hardware
- **Better memory efficiency** - uses less RAM for same data
- **Multi-threaded** - utilizes all CPU cores
- **100% Redis compatible** - no code changes needed
- **Built-in memory defragmentation**
- **Better performance under high load**

## Maintenance

### Backup DragonflyDB data:
```bash
redis-cli BGSAVE
# Backup files are in /var/lib/dragonfly/
```

### Monitor DragonflyDB:
```bash
# Real-time statistics
redis-cli --stat

# Memory usage
redis-cli INFO memory

# Connected clients
redis-cli CLIENT LIST
```

### Update DragonflyDB:
```bash
# Stop service
systemctl stop dragonfly

# Download and install new version (follow Step 3)
# Then restart
systemctl start dragonfly
```

## Rollback to Redis (if needed)

If you need to switch back to Redis:

```bash
# Stop DragonflyDB
systemctl stop dragonfly
systemctl disable dragonfly

# Remove symlinks
rm /etc/systemd/system/redis-server.service
rm /etc/systemd/system/redis.service

# Reinstall and start Redis
apt update
apt install -y redis-server
systemctl enable redis-server
systemctl start redis-server
```

---

**Note**: This guide is tested on CloudPanel with Ubuntu 22.04/24.04 and Debian 11/12. Always backup your data before making system changes.
