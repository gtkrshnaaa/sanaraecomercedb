# Remote Access Architecture, Network Security & RBAC Guide

## 1. Network Boundary Security on Linux Ubuntu

The dedicated database server must never expose administrative interfaces or unencrypted ports to the public internet. Access is secured using Linux UFW (Uncomplicated Firewall) and kernel iptables rules.

### Configuring UFW for Dedicated DB Server:
```bash
# Set default traffic policies
sudo ufw default deny incoming
sudo ufw default allow outgoing

# Allow SSH from management bastion host only
sudo ufw allow from 10.0.0.5 to any port 22 proto tcp comment "SSH Management Bastion"

# Allow MySQL port 3306 strictly from PHP Backend Application Subnet
sudo ufw allow from 10.0.1.0/24 to any port 3306 proto tcp comment "PHP Application Cluster"

# Enable Firewall
sudo ufw enable
sudo ufw status verbose
```

---

## 2. SSL/TLS Transport Encryption

All network packets traversing between the PHP application cluster and the dedicated MySQL database host are encrypted using TLS 1.3 to prevent eavesdropping and man-in-the-middle tampering.

### Server Certificate Generation:
The automated script `scripts/configure_server.sh` generates a dedicated Certificate Authority (CA) and server certificates in `/etc/mysql/ssl/`:
- `ca.pem`: Root certificate authority.
- `server-cert.pem`: Signed server certificate.
- `server-key.pem`: Server private key (permissions: 600, owner: `mysql:mysql`).

### Enabling TLS in `/etc/mysql/conf.d/sanara.cnf`:
```ini
[mysqld]
ssl_ca                  = /etc/mysql/ssl/ca.pem
ssl_cert                = /etc/mysql/ssl/server-cert.pem
ssl_key                 = /etc/mysql/ssl/server-key.pem
require_secure_transport = ON
tls_version             = TLSv1.3
```

---

## 3. Dedicated Remote Service Accounts & RBAC Matrix

In alignment with the Principle of Least Privilege (PoLP), remote accounts have isolated responsibilities:

| Account Identity | Host Mask | Allowed SQL Privileges | Purpose |
| :--- | :--- | :--- | :--- |
| **`sanara_app`** | `10.0.1.%` | `SELECT, INSERT, UPDATE, DELETE, EXECUTE` | Live PHP backend web application operations. |
| **`sanara_migrator`** | `10.0.1.%` | DDL + DML (`CREATE, DROP, ALTER, INDEX, TRIGGER, ...`) | CI/CD pipeline schema migration jobs. |
| **`sanara_ro`** | `10.0.1.%` | `SELECT, SHOW VIEW, EXECUTE` | Read-only analytics, BI dashboards, read-replicas. |
| **`sanara_backup`** | `localhost` | `SELECT, LOCK TABLES, SHOW VIEW, PROCESS, RELOAD` | Scheduled automated backup daemon. |
| **`sanara_replicator`**| `10.0.2.%` | `REPLICATION SLAVE, REPLICATION CLIENT` (Requires SSL) | Binary log GTID replica node synchronization. |

---

## 4. PHP Backend Integration Example (Laravel / PDO)

### Production PDO Connection Configuration with TLS Enforcement:
```php
<?php
// config/database.php or native PDO initialization

$host = '10.0.2.10'; // Dedicated MySQL Host Private IP
$db   = 'sanara_ecommerce';
$user = 'sanara_app';
$pass = 'SanaraApp_SecurePass2026!';
$port = 3306;

$dsn = "mysql:host={$host};port={$port};dbname={$db};charset=utf8mb4";

$options = [
    PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
    PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
    PDO::ATTR_EMULATE_PREPARES   => false,
    
    // TLS / SSL Encryption Directives
    PDO::MYSQL_ATTR_SSL_CA       => '/etc/ssl/certs/sanara-ca.pem',
    PDO::MYSQL_ATTR_SSL_VERIFY_SERVER_CERT => true,
    
    // Connection Pool Keepalive
    PDO::ATTR_PERSISTENT         => false,
    PDO::ATTR_TIMEOUT            => 5,
];

try {
    $pdo = new PDO($dsn, $user, $pass, $options);
} catch (PDOException $e) {
    throw new RuntimeException("Database connection failure: " . $e->getMessage(), (int)$e->getCode());
}
```

---

## 5. Security Audit Logging

All administrative actions, curator quality reviews, and sensitive financial adjustments are recorded in `system_audit_logs`:
- Actor User ID
- Timestamp
- Client IP address
- Action type (`PRODUCT_QA_APPROVED`, `PAYOUT_DISBURSED`)
- JSON snapshots of before-and-after states.
