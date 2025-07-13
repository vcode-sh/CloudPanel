#!/bin/bash

# DragonflyDB Test Script for CloudPanel
# Tests if DragonflyDB is properly installed and working

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo
echo "DragonflyDB Installation Test"
echo "============================="
echo

# Test 1: Service Status
echo -n "1. Checking DragonflyDB service... "
if systemctl is-active --quiet dragonfly; then
    echo -e "${GREEN}✓ Active${NC}"
else
    echo -e "${RED}✗ Not Active${NC}"
fi

# Test 2: Redis Alias
echo -n "2. Checking Redis service alias... "
if systemctl is-active --quiet redis-server; then
    echo -e "${GREEN}✓ Active${NC}"
else
    echo -e "${RED}✗ Not Active${NC}"
fi

# Test 3: Port Listening
echo -n "3. Checking port 6379... "
if ss -tlnp 2>/dev/null | grep -q ":6379"; then
    echo -e "${GREEN}✓ Listening${NC}"
else
    echo -e "${RED}✗ Not Listening${NC}"
fi

# Test 4: Redis CLI Connection
echo -n "4. Testing Redis CLI connection... "
if redis-cli ping 2>/dev/null | grep -q "PONG"; then
    echo -e "${GREEN}✓ Connected${NC}"
else
    echo -e "${RED}✗ Failed${NC}"
fi

# Test 5: DragonflyDB Version
echo -n "5. Checking DragonflyDB version... "
VERSION=$(redis-cli INFO server 2>/dev/null | grep dragonfly_version | cut -d: -f2 | tr -d '\r' || echo "Not Found")
if [[ "$VERSION" != "Not Found" && -n "$VERSION" ]]; then
    echo -e "${GREEN}✓ $VERSION${NC}"
else
    echo -e "${RED}✗ Not Found${NC}"
fi

# Test 6: PHP Connection
echo -n "6. Testing PHP Redis connection... "
PHP_TEST=$(mktemp)
cat > "$PHP_TEST" << 'EOF'
<?php
try {
    $redis = new Redis();
    $redis->connect('127.0.0.1', 6379);
    echo "SUCCESS";
} catch (Exception $e) {
    echo "FAILED";
}
EOF

if [[ $(php "$PHP_TEST" 2>/dev/null) == "SUCCESS" ]]; then
    echo -e "${GREEN}✓ Connected${NC}"
else
    echo -e "${YELLOW}⚠ Failed (PHP Redis extension may not be installed)${NC}"
fi
rm -f "$PHP_TEST"

# Test 7: Memory Configuration
echo -n "7. Checking memory configuration... "
MAX_MEM=$(redis-cli INFO memory 2>/dev/null | grep "maxmemory:" | cut -d: -f2 | tr -d '\r' || echo "Not Set")
if [[ "$MAX_MEM" != "Not Set" && -n "$MAX_MEM" ]]; then
    echo -e "${GREEN}✓ $MAX_MEM${NC}"
else
    echo -e "${RED}✗ Not Set${NC}"
fi

# Summary
echo
echo "Summary"
echo "-------"
TOTAL_MEM_KB=$(grep MemTotal /proc/meminfo | awk '{print $2}')
TOTAL_MEM_GB=$((TOTAL_MEM_KB / 1024 / 1024))
echo "System Memory: ${TOTAL_MEM_GB}GB"
echo "DragonflyDB Status: $(systemctl is-active dragonfly)"
echo "Config File: /etc/dragonfly/dragonfly.conf"
echo "Data Directory: /var/lib/dragonfly"
echo "Log: journalctl -xeu dragonfly"
echo