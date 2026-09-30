#!/usr/bin/env bash
# ==============================================================================
# Sanara E-Commerce Server Security & Network Provisioning Script
# Target: Remote Network Bind, Firewall (UFW), and SSL/TLS Configuration
# ==============================================================================

set -euo pipefail

APP_BACKEND_CIDR="${1:-10.0.0.0/16}"
SSL_DIR="/etc/mysql/ssl"

echo "Configuring dedicated MySQL host for remote backend connectivity..."
echo "Permitted backend subnet: ${APP_BACKEND_CIDR}"

# 1. Firewall rules via UFW (if available and enabled)
if command -v ufw >/dev/null 2>&1; then
    echo "Configuring UFW firewall rules..."
    ufw allow 22/tcp comment "SSH administration" || true
    ufw allow from "${APP_BACKEND_CIDR}" to any port 3306 proto tcp comment "MySQL access from PHP backend nodes" || true
    echo "  UFW rule added for MySQL port 3306 from ${APP_BACKEND_CIDR}"
fi

# 2. SSL/TLS Certificate Provisioning for Secure Remote Transport
if [ ! -f "${SSL_DIR}/server-cert.pem" ]; then
    echo "Generating dedicated SSL/TLS certificates for MySQL encryption..."
    mkdir -p "${SSL_DIR}"
    
    # Generate CA
    openssl genrsa 2048 > "${SSL_DIR}/ca-key.pem" 2>/dev/null
    openssl req -new -x509 -nodes -days 3650 \
        -key "${SSL_DIR}/ca-key.pem" \
        -out "${SSL_DIR}/ca.pem" \
        -subj "/CN=Sanara-Database-CA" 2>/dev/null

    # Generate Server Key & CSR
    openssl req -newkey rsa:2048 -days 3650 -nodes \
        -keyout "${SSL_DIR}/server-key.pem" \
        -out "${SSL_DIR}/server-req.pem" \
        -subj "/CN=db.sanara.internal" 2>/dev/null
    
    # Sign Server Cert
    openssl rsa -in "${SSL_DIR}/server-key.pem" -out "${SSL_DIR}/server-key.pem" 2>/dev/null
    openssl x509 -req -in "${SSL_DIR}/server-req.pem" -days 3650 \
        -CA "${SSL_DIR}/ca.pem" -CAkey "${SSL_DIR}/ca-key.pem" -set_serial 01 \
        -out "${SSL_DIR}/server-cert.pem" 2>/dev/null

    chown -R mysql:mysql "${SSL_DIR}"
    chmod 600 "${SSL_DIR}"/*-key.pem
    chmod 644 "${SSL_DIR}"/*.pem
    echo "  SSL certificates generated in ${SSL_DIR}"
else
    echo "  SSL certificates already present in ${SSL_DIR}"
fi

echo "Remote server security and networking configuration ready."
