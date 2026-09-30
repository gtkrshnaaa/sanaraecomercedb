#!/usr/bin/env bash
# ==============================================================================
# Sanara E-Commerce Master Single-Enter Deployment & Provisioning Orchestrator
# Target: Dedicated Linux Ubuntu Server (Remote Database Tier)
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "========================================================================"
echo "Starting Sanara E-Commerce Dedicated Database Server Deployment"
echo "Platform: Linux Ubuntu Server"
echo "Architecture: Remote Standalone MySQL 8.0 Node for PHP Application Tier"
echo "========================================================================"

# Step 1: Install MySQL Server, Client and Monitoring Tools
echo ">>> [Phase 1/4] Installing MySQL Server and System Dependencies..."
bash "${SCRIPT_DIR}/scripts/install_mysql_ubuntu.sh"

# Step 2: Configure Server Security, UFW Firewall and SSL Transport
echo ">>> [Phase 2/4] Hardening Network, Firewall, and SSL Transport..."
bash "${SCRIPT_DIR}/scripts/configure_server.sh" "10.0.0.0/16"

# Step 3: Initialize Schemas, Triggers, Routines, and Rich Seed Catalog
echo ">>> [Phase 3/4] Initializing Database Schema, Routines, and Datasets..."
bash "${SCRIPT_DIR}/scripts/init_database.sh"

# Step 4: Run Live System Health Diagnostics
echo ">>> [Phase 4/4] Executing Live Health Diagnostics..."
bash "${SCRIPT_DIR}/scripts/health_check.sh"

echo "========================================================================"
echo "DEPLOYMENT COMPLETE: Sanara Database Node is Operational & Ready for PHP"
echo "Database: sanara_ecommerce | Port: 3306"
echo "Application User: sanara_app (Restricted DML)"
echo "Read-Only User:   sanara_ro  (Analytics & BI Replicas)"
echo "========================================================================"
