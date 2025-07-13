# DragonflyDB CloudPanel Installer Makefile

.PHONY: install test status stop start restart logs uninstall help

# Default target
help:
	@echo "DragonflyDB CloudPanel Manager"
	@echo "=============================="
	@echo ""
	@echo "Available commands:"
	@echo "  make install    - Install DragonflyDB (replaces Redis)"
	@echo "  make test       - Test DragonflyDB installation"
	@echo "  make status     - Show service status"
	@echo "  make start      - Start DragonflyDB service"
	@echo "  make stop       - Stop DragonflyDB service"
	@echo "  make restart    - Restart DragonflyDB service"
	@echo "  make logs       - Show live logs"
	@echo "  make uninstall  - Remove DragonflyDB and restore Redis"
	@echo "  make help       - Show this help"

# Install DragonflyDB
install:
	@echo "Starting DragonflyDB installation..."
	@sudo ./install-dragonfly-cloudpanel.sh

# Test installation
test:
	@./test-dragonfly.sh

# Show status
status:
	@echo "DragonflyDB Status:"
	@systemctl status dragonfly --no-pager -l
	@echo ""
	@echo "Redis Alias Status:"
	@systemctl status redis-server --no-pager -l

# Start service
start:
	@sudo systemctl start dragonfly
	@echo "DragonflyDB started"

# Stop service
stop:
	@sudo systemctl stop dragonfly
	@echo "DragonflyDB stopped"

# Restart service
restart:
	@sudo systemctl restart dragonfly
	@echo "DragonflyDB restarted"

# Show logs
logs:
	@sudo journalctl -xeu dragonfly -f

# Uninstall DragonflyDB and restore Redis
uninstall:
	@echo "This will remove DragonflyDB and restore Redis"
	@read -p "Are you sure? (y/N): " confirm && [ "$$confirm" = "y" ] || exit 0
	@echo "Stopping DragonflyDB..."
	@sudo systemctl stop dragonfly || true
	@sudo systemctl disable dragonfly || true
	@echo "Removing service files..."
	@sudo rm -f /etc/systemd/system/dragonfly.service
	@sudo rm -f /etc/systemd/system/redis-server.service
	@sudo rm -f /etc/systemd/system/redis.service
	@sudo rm -f /usr/local/bin/redis-server
	@sudo systemctl daemon-reload
	@echo "Reinstalling Redis..."
	@sudo apt update
	@sudo apt install -y redis-server
	@sudo systemctl enable redis-server
	@sudo systemctl start redis-server
	@echo "Redis restored successfully"

# Quick setup from GitHub
setup:
	@echo "Downloading latest files from GitHub..."
	@wget -q https://raw.githubusercontent.com/vcode-sh/CloudPanel/main/dragonflydb/install-dragonfly-cloudpanel.sh
	@wget -q https://raw.githubusercontent.com/vcode-sh/CloudPanel/main/dragonflydb/test-dragonfly.sh
	@chmod +x install-dragonfly-cloudpanel.sh test-dragonfly.sh
	@echo "Files downloaded. Run 'make install' to proceed."