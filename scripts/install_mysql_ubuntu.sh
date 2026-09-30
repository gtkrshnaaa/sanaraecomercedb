#!/usr/bin/env bash
# ==============================================================================
# Sanara E-Commerce Database Server Installation Script
# Target Platform: Ubuntu 22.04 / 24.04 LTS (Dedicated DB Host)
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

echo "[1/6] Validating environment and dependencies..."
if [ "$(id -u)" -ne 0 ]; then
    echo "ERROR: This script must be run as root." >&2
    exit 1
fi

export DEBIAN_FRONTEND=noninteractive

echo "[2/6] Installing MySQL Server, Client, and monitoring utilities..."
apt-get update -y
apt-get install -y --no-install-recommends \
    mysql-server \
    mysql-client \
    openssl \
    ca-certificates \
    sysstat \
    curl

echo "[3/6] Applying Linux kernel and resource limit tunings..."
if [ -w /etc/security/limits.d ]; then
    cp "${PROJECT_ROOT}/config/security/limits.conf" /etc/security/limits.d/99-mysql.conf
    echo "  Resource limits applied to /etc/security/limits.d/99-mysql.conf"
fi

# Apply sysctl settings if in standard Linux VM/bare-metal kernel environment
if command -v sysctl >/dev/null 2>&1 && [ -f "${PROJECT_ROOT}/config/sysctl.d/99-mysql-tuning.conf" ]; then
    cp "${PROJECT_ROOT}/config/sysctl.d/99-mysql-tuning.conf" /etc/sysctl.d/99-mysql-tuning.conf
    sysctl --system >/dev/null 2>&1 || echo "  Notice: sysctl adjustments skipped in container/chroot."
fi

echo "[4/6] Installing production MySQL configuration..."
mkdir -p /etc/mysql/conf.d
cp "${PROJECT_ROOT}/config/mysql.cnf" /etc/mysql/conf.d/sanara.cnf
chmod 644 /etc/mysql/conf.d/sanara.cnf

# Ensure runtime directories exist
mkdir -p /var/run/mysqld /var/log/mysql /var/lib/mysql
chown -R mysql:mysql /var/run/mysqld /var/log/mysql /var/lib/mysql

echo "[5/6] Starting MySQL Server service..."
if command -v systemctl >/dev/null 2>&1 && [ -d /run/systemd/system ]; then
    systemctl enable mysql
    systemctl restart mysql
else
    /etc/init.d/mysql restart || /etc/init.d/mysql start
fi

echo "[6/6] Verifying MySQL connection..."
mysqladmin ping --silent
echo "SUCCESS: MySQL Server installed, configured, and operational."
