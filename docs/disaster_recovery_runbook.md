# Disaster Recovery Runbook & Backup Procedures

## 1. Backup Strategy Overview

Sanara enforces a multi-tiered disaster recovery strategy combining **daily consistent logical snapshots** with **continuous binary log archiving** for zero data loss Point-In-Time Recovery (PITR).

| Backup Component | Tool | Frequency | Retention Window | Destination |
| :--- | :--- | :--- | :--- | :--- |
| **Full Logical Snapshot** | `scripts/backup.sh` (`mysqldump`) | Daily at 02:00 UTC | 14 Days | Offsite S3 Bucket |
| **Continuous Binlogs** | MySQL GTID Binary Logs | Continuous Real-Time | 7 Days | Dedicated Log Volume |
| **Integrity Signatures** | SHA-256 Checksums | Generated per snapshot | 14 Days | Co-located with archive |

---

## 2. Automated Daily Backup Execution

The backup script utilizes `--single-transaction` to ensure ACID consistency without locking active e-commerce tables:

```bash
# Execute manual backup or trigger via system crontab
sudo /root/project/dbengineering/sanaraecomercedb/scripts/backup.sh /var/backups/sanara_mysql
```

### Production Crontab Entry (`/etc/cron.d/sanara-mysql-backup`):
```cron
# Daily backup at 02:00 AM UTC
0 2 * * * root /root/project/dbengineering/sanaraecomercedb/scripts/backup.sh /var/backups/sanara_mysql >> /var/log/mysql/backup.log 2>&1
```

---

## 3. Disaster Recovery Restoration Procedure

### Standard Restore (From Snapshot):
```bash
sudo /root/project/dbengineering/sanaraecomercedb/scripts/restore.sh \
    /var/backups/sanara_mysql/sanara_ecommerce_backup_20260930_003319.sql.gz \
    sanara_ecommerce
```

**Restoration Steps Executed Automatically**:
1. Checks SHA-256 archive signature against `.sha256` checksum file.
2. Streams compressed archive through `zcat` directly to the `mysql` client.
3. Queries `information_schema.tables` to verify table presence and row counts.

---

## 4. Point-In-Time Recovery (PITR) Workflow

In the event of accidental data corruption (e.g. an unintended `DELETE` or `UPDATE` executed at `2026-09-30 14:15:00`):

### Step 1: Restore the Most Recent Full Snapshot
```bash
sudo bash scripts/restore.sh /var/backups/sanara_mysql/sanara_ecommerce_backup_20260930_020000.sql.gz sanara_ecommerce
```

### Step 2: Extract Post-Backup Binary Log Coordinates
Inspect the restored backup file header or metadata for the starting binary log position:
```bash
zcat /var/backups/sanara_mysql/sanara_ecommerce_backup_20260930_020000.sql.gz | head -n 40 | grep "CHANGE MASTER"
```

### Step 3: Replay Binary Logs Up to the Target Timestamp
Replay all transactions committed between 02:00:00 and 14:14:59, stopping immediately before the corruption event:

```bash
mysqlbinlog \
    --start-datetime="2026-09-30 02:00:00" \
    --stop-datetime="2026-09-30 14:14:59" \
    --database=sanara_ecommerce \
    /var/log/mysql/mysql-bin.000042 \
    /var/log/mysql/mysql-bin.000043 | mysql -u root sanara_ecommerce
```

### Step 4: Verify Consistency & Re-enable Application Traffic
Execute `scripts/health_check.sh` and `test.sh` to validate integrity before updating DNS routing.
