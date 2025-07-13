# CloudPanel DragonflyDB Installer

![License](https://img.shields.io/badge/license-MIT-blue.svg)
![OS Support](https://img.shields.io/badge/OS-Ubuntu%2022.04%2F24.04%20%7C%20Debian%2011%2F12-green.svg)
![Architecture](https://img.shields.io/badge/Architecture-x86__64%20%7C%20ARM64-yellow.svg)
![CloudPanel](https://img.shields.io/badge/CloudPanel-Compatible-brightgreen.svg)

**Replace Redis with DragonflyDB on CloudPanel for 25x better performance!**

Automated installer script to seamlessly replace Redis with DragonflyDB on CloudPanel servers. DragonflyDB is a modern, high-performance, Redis-compatible in-memory data store that's 25x faster than Redis.

## 🚀 Quick Start

### One-Command Installation

```bash
curl -sSL https://raw.githubusercontent.com/vcode-sh/CloudPanel/main/dragonflydb/install-dragonfly-cloudpanel.sh | sudo bash
```

### Alternative (Recommended for Production)

```bash
wget https://raw.githubusercontent.com/vcode-sh/CloudPanel/main/dragonflydb/install-dragonfly-cloudpanel.sh
chmod +x install-dragonfly-cloudpanel.sh
sudo ./install-dragonfly-cloudpanel.sh
```

### Using Git Repository

```bash
git clone https://github.com/vcode-sh/CloudPanel.git
cd CloudPanel/dragonflydb
make install
```

## 📋 What This Script Does

✅ **Automatic OS & Architecture Detection** (Ubuntu 22.04/24.04, Debian 11/12, x86_64/ARM64)  
✅ **Redis Data Backup** (optional, before migration)  
✅ **Optimal Memory Configuration** (based on your system RAM)  
✅ **CloudPanel Integration** (shows Redis as "Active" in Services)  
✅ **Full Redis Compatibility** (no code changes needed)  
✅ **Error Handling & Logging** (comprehensive error recovery)  
✅ **Post-Installation Testing** (verifies everything works)

## 🎯 Benefits

| Feature | Redis | DragonflyDB |
|---------|-------|-------------|
| **Performance** | Baseline | **25x faster** |
| **Memory Usage** | High | **50% less memory** |
| **CPU Utilization** | Single-threaded | **Multi-threaded** |
| **Compatibility** | 100% | **100% Redis compatible** |
| **Defragmentation** | Manual | **Built-in automatic** |

## 📊 System Requirements

- **OS**: Ubuntu 22.04/24.04 or Debian 11/12
- **Architecture**: x86_64 or ARM64
- **RAM**: Minimum 2GB (4GB+ recommended)
- **CloudPanel**: Must be installed
- **Access**: Root privileges required

## 🧪 Testing Your Installation

Download and run the test script:

```bash
wget https://raw.githubusercontent.com/vcode-sh/CloudPanel/main/dragonflydb/test-dragonfly.sh
chmod +x test-dragonfly.sh
./test-dragonfly.sh
```

Expected output:
```
DragonflyDB Installation Test
=============================

1. Checking DragonflyDB service... ✓ Active
2. Checking Redis service alias... ✓ Active
3. Checking port 6379... ✓ Listening
4. Testing Redis CLI connection... ✓ Connected
5. Checking DragonflyDB version... ✓ df-v1.31.0
6. Testing PHP Redis connection... ✓ Connected
7. Checking memory configuration... ✓ 4GB
```

## 🛠️ Management Commands

### Basic Commands
```bash
# Check status
systemctl status dragonfly
systemctl status redis-server  # Same as above

# View logs
journalctl -xeu dragonfly -f

# Restart service
systemctl restart dragonfly

# Connect via CLI
redis-cli
127.0.0.1:6379> INFO server
```

### Using Makefile (from repository)
```bash
git clone https://github.com/vcode-sh/CloudPanel.git
cd CloudPanel/dragonflydb

make help        # Show all commands
make test        # Test installation
make status      # Show service status
make logs        # View live logs
make restart     # Restart service
make uninstall   # Restore Redis
```

## 📈 Performance Tuning

The script automatically configures optimal settings based on your system:

| System RAM | DragonflyDB Memory | Max Connections |
|------------|-------------------|-----------------|
| 4GB        | 1GB               | 1000           |
| 8GB        | 2GB               | 2000           |
| 16GB       | 4GB               | 5000           |
| 32GB       | 8GB               | 10000          |
| 64GB+      | 16GB+             | 10000+         |

## 🐛 Troubleshooting

### CloudPanel Shows Redis as Stopped

1. **Check service status:**
   ```bash
   systemctl is-active redis-server
   ```

2. **Clear browser cache and reload CloudPanel**

3. **Restart PHP-FPM:**
   ```bash
   systemctl restart php*-fpm
   ```

### DragonflyDB Won't Start

```bash
# Check detailed logs
journalctl -xeu dragonfly.service -n 50

# Verify configuration
/usr/local/bin/dragonfly --flagfile=/etc/dragonfly/dragonfly.conf --dry-run

# Check port conflicts
ss -tlnp | grep 6379
```

### PHP Can't Connect

```bash
# Install PHP Redis extension
apt-get install -y php-redis
systemctl restart php*-fpm
```

## 🔙 Rollback to Redis

If you need to revert back to Redis:

```bash
# Using the uninstall feature (from repository)
cd CloudPanel/dragonflydb
make uninstall

# Or manually
systemctl stop dragonfly
systemctl disable dragonfly
rm /etc/systemd/system/redis-server.service
apt install -y redis-server
systemctl enable redis-server
systemctl start redis-server
```

## 📚 Documentation

- [**Detailed Installation Guide**](dragonfly.md) - Step-by-step manual process
- [**DragonflyDB Official Docs**](https://www.dragonflydb.io/docs) - Comprehensive documentation
- [**CloudPanel Documentation**](https://www.cloudpanel.io/docs) - CloudPanel guides

## 📁 Repository Structure

```
CloudPanel/
└── dragonflydb/
    ├── install-dragonfly-cloudpanel.sh  # Main installer
    ├── test-dragonfly.sh               # Test script
    ├── dragonfly.md                    # Detailed guide
    ├── Makefile                        # Management commands
    ├── README.md                       # This file
    └── docs/                           # Additional documentation
```

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

### Reporting Issues

When reporting issues, please include:
- OS and version (`cat /etc/os-release`)
- Architecture (`uname -m`)
- CloudPanel version
- Installation log (`/var/log/dragonfly-installer.log`)

## 📄 License

MIT License - see [LICENSE](LICENSE) file for details.

## ⭐ Support

If this project helped you, please consider giving it a star on GitHub!

---

**Made with ❤️ for the CloudPanel community**

*Boost your CloudPanel performance today with DragonflyDB!*