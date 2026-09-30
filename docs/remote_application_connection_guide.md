# Remote Standalone Database Integration & Connection Guide

## 1. Architectural Connectivity Mechanics

In a production tier-separated topology, the Sanara MySQL 8.0 server operates on a standalone, dedicated Linux Ubuntu host (`10.0.2.10`) isolated from the PHP application cluster (`10.0.1.0/24`).

```mermaid
sequenceDiagram
    autonumber
    participant App as PHP Application Node<br/>(10.0.1.50)
    participant FW as Linux UFW / Netfilter<br/>(10.0.2.10)
    participant TLS as TLS 1.3 Handshake<br/>(/etc/mysql/ssl/ca.pem)
    participant Auth as MySQL Auth Engine<br/>(caching_sha2_password)
    participant DB as InnoDB Storage Engine<br/>(sanara_ecommerce)

    App->>FW: TCP SYN packet to 10.0.2.10:3306
    FW->>App: TCP SYN-ACK (Subnet 10.0.1.0/24 authorized)
    App->>TLS: Client Hello (STARTTLS protocol)
    TLS->>App: Server Hello + Certificate (CN=db.sanara.internal)
    Note over App,TLS: App verifies server cert against local sanara-db-ca.pem
    App->>Auth: Encrypted Handshake (User: sanara_app, Nonce)
    Auth->>App: Authentication Accepted (Access granted to sanara_ecommerce)
    App->>DB: DML Query (e.g. SELECT, INSERT, CALL sp_checkout_order)
    DB->>App: Tabular Result Set / Binary Stream
```

---

## 2. Step 1: Network Reachability & Firewall Provisioning

Before initiating software connections, establish network reachability through private routing and Linux firewall rules.

### A. On the Dedicated Database Host (`10.0.2.10`)
Ensure MySQL binds to the private network interface and permit traffic from the application subnet:

```bash
# 1. Inspect MySQL bind address in /etc/mysql/conf.d/sanara.cnf
# Must be set to 0.0.0.0 or the private interface IP (10.0.2.10)
grep -E "bind-address" /etc/mysql/conf.d/sanara.cnf

# 2. Authorize PHP Application Subnet in UFW
sudo ufw allow from 10.0.1.0/24 to any port 3306 proto tcp comment "PHP App Cluster"
sudo ufw reload
sudo ufw status verbose
```

### B. On the PHP Application Node (`10.0.1.50`)
Verify TCP port reachability from the application shell before configuring PHP:

```bash
# Test raw TCP socket connectivity
nc -zv -w 3 10.0.2.10 3306
# Expected output: Connection to 10.0.2.10 3306 port [tcp/mysql] succeeded!

# Test network path latency and MTU
ping -c 3 10.0.2.10
tracepath 10.0.2.10
```

---

## 3. Step 2: SSL/TLS Certificate Distribution

Because database traffic traverses private subnet boundaries, TLS 1.3 transport encryption is strictly enforced.

### A. Distribute the Root CA from the Database Host
Copy `/etc/mysql/ssl/ca.pem` from the database host to the application nodes:

```bash
# On Database Host: View or copy CA certificate
cat /etc/mysql/ssl/ca.pem

# On Application Host: Save certificate into trusted system store
sudo mkdir -p /etc/ssl/certs/sanara
sudo cp ca.pem /etc/ssl/certs/sanara/sanara-db-ca.pem
sudo chmod 644 /etc/ssl/certs/sanara/sanara-db-ca.pem
```

### B. Validate TLS Handshake via CLI
```bash
mysql -h 10.0.2.10 -u sanara_app -p'SanaraApp_SecurePass2026!' \
    --ssl-ca=/etc/ssl/certs/sanara/sanara-db-ca.pem \
    --ssl-mode=VERIFY_CA \
    -e "STATUS;" | grep -E "SSL|Cipher"
```
Expected output:
```text
SSL:                    Cipher in use is TLS_AES_256_GCM_SHA384
```

---

## 4. Step 3: Remote Authentication & Service Credentials

Use dedicated accounts matching the operational task:

| Account | Application Usage | Privileges |
| :--- | :--- | :--- |
| **`sanara_app`** | PHP Web App, API, Queue Workers | `SELECT, INSERT, UPDATE, DELETE, EXECUTE` (Zero DDL) |
| **`sanara_migrator`** | CI/CD Deployment Pipelines (`artisan migrate`) | Full DDL + DML (`CREATE, ALTER, DROP, INDEX, TRIGGER`) |
| **`sanara_ro`** | Business Intelligence & Read Replicas | `SELECT, SHOW VIEW, EXECUTE` |

---

## 5. Step 4: Framework Integration Blueprints

### Blueprint A: Laravel Framework (`.env` and `config/database.php`)

#### `.env` Configuration:
```dotenv
DB_CONNECTION=mysql
DB_HOST=10.0.2.10
DB_PORT=3306
DB_DATABASE=sanara_ecommerce
DB_USERNAME=sanara_app
DB_PASSWORD=SanaraApp_SecurePass2026!
MYSQL_ATTR_SSL_CA=/etc/ssl/certs/sanara/sanara-db-ca.pem

# Dedicated Migration User for CI/CD Deployment
DB_MIGRATOR_USERNAME=sanara_migrator
DB_MIGRATOR_PASSWORD=SanaraMigrator_Key2026!

# Read Replica Configuration (Optional)
DB_READ_HOST=10.0.2.11
```

#### `config/database.php` (Read/Write Splitting + TLS):
```php
<?php

return [
    'default' => env('DB_CONNECTION', 'mysql'),

    'connections' => [
        'mysql' => [
            'driver' => 'mysql',
            'url' => env('DATABASE_URL'),
            'read' => [
                'host' => [env('DB_READ_HOST', env('DB_HOST', '10.0.2.10'))],
            ],
            'write' => [
                'host' => [env('DB_HOST', '10.0.2.10')],
            ],
            'sticky' => true,
            'port' => env('DB_PORT', '3306'),
            'database' => env('DB_DATABASE', 'sanara_ecommerce'),
            'username' => env('DB_USERNAME', 'sanara_app'),
            'password' => env('DB_PASSWORD', 'SanaraApp_SecurePass2026!'),
            'charset' => 'utf8mb4',
            'collation' => 'utf8mb4_0900_ai_ci',
            'prefix' => '',
            'prefix_indexes' => true,
            'strict' => true,
            'engine' => 'InnoDB',
            'options' => array_filter([
                PDO::MYSQL_ATTR_SSL_CA => env('MYSQL_ATTR_SSL_CA'),
                PDO::MYSQL_ATTR_SSL_VERIFY_SERVER_CERT => true,
                PDO::ATTR_TIMEOUT => 5,
                PDO::ATTR_EMULATE_PREPARES => false,
            ]),
        ],

        // Dedicated connection used strictly by 'php artisan migrate'
        'migrator' => [
            'driver' => 'mysql',
            'host' => env('DB_HOST', '10.0.2.10'),
            'port' => env('DB_PORT', '3306'),
            'database' => env('DB_DATABASE', 'sanara_ecommerce'),
            'username' => env('DB_MIGRATOR_USERNAME', 'sanara_migrator'),
            'password' => env('DB_MIGRATOR_PASSWORD', 'SanaraMigrator_Key2026!'),
            'charset' => 'utf8mb4',
            'collation' => 'utf8mb4_0900_ai_ci',
            'strict' => true,
            'engine' => 'InnoDB',
            'options' => array_filter([
                PDO::MYSQL_ATTR_SSL_CA => env('MYSQL_ATTR_SSL_CA'),
            ]),
        ],
    ],
];
```

---

### Blueprint B: Symfony Framework & Doctrine ORM

#### `.env.local`:
```dotenv
DATABASE_URL="mysql://sanara_app:SanaraApp_SecurePass2026%21@10.0.2.10:3306/sanara_ecommerce?serverVersion=8.0.46-0ubuntu0.24.04.4&charset=utf8mb4"
```

#### `config/packages/doctrine.yaml`:
```yaml
doctrine:
    dbal:
        url: '%env(resolve:DATABASE_URL)%'
        options:
            !php/const PDO::MYSQL_ATTR_SSL_CA: '/etc/ssl/certs/sanara/sanara-db-ca.pem'
            !php/const PDO::MYSQL_ATTR_SSL_VERIFY_SERVER_CERT: true
            !php/const PDO::ATTR_TIMEOUT: 5
            !php/const PDO::ATTR_EMULATE_PREPARES: false
```

---

### Blueprint C: Production Raw PHP PDO Connector Factory

For microservices, queue workers, or custom PHP services requiring automated reconnection, transaction safety, and deadlock retries:

```php
<?php
declare(strict_types=1);

namespace Sanara\Infrastructure\Database;

use PDO;
use PDOException;
use RuntimeException;

final class DatabaseConnector
{
    private static ?PDO $instance = null;

    public static function getConnection(): PDO
    {
        if (self::$instance !== null) {
            return self::$instance;
        }

        $host = getenv('DB_HOST') ?: '10.0.2.10';
        $port = getenv('DB_PORT') ?: '3306';
        $db   = getenv('DB_DATABASE') ?: 'sanara_ecommerce';
        $user = getenv('DB_USERNAME') ?: 'sanara_app';
        $pass = getenv('DB_PASSWORD') ?: 'SanaraApp_SecurePass2026!';
        $ca   = getenv('MYSQL_ATTR_SSL_CA') ?: '/etc/ssl/certs/sanara/sanara-db-ca.pem';

        $dsn = sprintf('mysql:host=%s;port=%s;dbname=%s;charset=utf8mb4', $host, $port, $db);

        $options = [
            PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
            PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
            PDO::ATTR_EMULATE_PREPARES   => false,
            PDO::ATTR_TIMEOUT            => 5,
            PDO::ATTR_PERSISTENT         => false, // Managed per PHP-FPM worker lifecycle
        ];

        if (file_exists($ca)) {
            $options[PDO::MYSQL_ATTR_SSL_CA] = $ca;
            $options[PDO::MYSQL_ATTR_SSL_VERIFY_SERVER_CERT] = true;
        }

        $attempts = 0;
        $maxAttempts = 3;

        while ($attempts < $maxAttempts) {
            try {
                self::$instance = new PDO($dsn, $user, $pass, $options);
                return self::$instance;
            } catch (PDOException $e) {
                $attempts++;
                if ($attempts >= $maxAttempts) {
                    throw new RuntimeException("Database connection failure after {$attempts} attempts: " . $e->getMessage(), (int)$e->getCode());
                }
                usleep(200000 * $attempts); // Exponential backoff (200ms, 400ms)
            }
        }

        throw new RuntimeException("Unexpected connection initialization error.");
    }
}
```

---

## 6. Connection Tuning, Keepalive & Timeouts

When running high-traffic PHP-FPM clusters connecting to a standalone database host, adhere to the following pool guidelines:

1. **Persistent Connections (`PDO::ATTR_PERSISTENT`)**:
   - Set to `false` for standard PHP-FPM web traffic. PHP-FPM pool sizing (e.g. 50 workers per node across 4 nodes = 200 connections) fits cleanly inside MySQL's `max_connections = 500`.
   - Avoid persistent connections unless an intermediary connection pooler like ProxySQL or AWS RDS Proxy is deployed.
2. **Timeout Alignment**:
   - MySQL `wait_timeout = 600` (10 minutes).
   - MySQL `interactive_timeout = 600`.
   - PHP `PDO::ATTR_TIMEOUT = 5` (fails fast on network blips rather than hanging PHP worker threads).
3. **TCP Socket Keepalives**:
   Ensures idle connections held across cloud load balancers or stateful firewalls do not get silently dropped:
   ```ini
   net.ipv4.tcp_keepalive_time = 300
   net.ipv4.tcp_keepalive_intvl = 15
   net.ipv4.tcp_keepalive_probes = 5
   ```

---

## 7. Troubleshooting & Diagnostic Checklist

| Error Code / Message | Root Cause | Technical Resolution |
| :--- | :--- | :--- |
| **`ERROR 2003 (HY000): Can't connect to MySQL server`** | UFW firewall blocking port 3306 or MySQL bound strictly to `127.0.0.1`. | Verify `bind-address = 0.0.0.0` in `config/mysql.cnf`. Run `sudo ufw allow from 10.0.1.0/24 to any port 3306`. |
| **`ERROR 1045 (28000): Access denied for user 'sanara_app'`** | Invalid password or user host mask mismatch. | Verify host mask: `SELECT user, host FROM mysql.user WHERE user='sanara_app';`. Ensure host pattern matches application IP subnet (e.g. `%` or `10.0.1.%`). |
| **`ERROR 2026 (HY000): SSL connection error`** | CA certificate path invalid or certificate expired. | Validate `/etc/ssl/certs/sanara/sanara-db-ca.pem` path. Test with `openssl verify -CAfile ca.pem ca.pem`. |
| **`ERROR 1130 (HY000): Host is not allowed to connect`** | Client IP not authorized in MySQL grant tables. | Check MySQL user table: `GRANT ... ON sanara_ecommerce.* TO 'sanara_app'@'10.0.1.%'; FLUSH PRIVILEGES;`. |
| **`ERROR 1205 (HY000): Lock wait timeout exceeded`** | Long-running transaction or deadlock holding rows. | Inspect locked transactions: `SELECT * FROM performance_schema.data_locks;` and `SHOW ENGINE INNODB STATUS;`. |
