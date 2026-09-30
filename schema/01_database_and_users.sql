-- ==============================================================================
-- Sanara E-Commerce Database Architecture
-- Script 01: Database Provisioning, Remote Service Users, and RBAC Grants
-- Principle: Separation of Concerns, Least Privilege, Remote Host Segmentation
-- ==============================================================================

-- 1. Database Creation
CREATE DATABASE IF NOT EXISTS `sanara_ecommerce`
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_0900_ai_ci;

USE `sanara_ecommerce`;

-- Enable trusted function and trigger creation in replication/binlog environments
SET GLOBAL log_bin_trust_function_creators = 1;

-- 2. Clean up existing users for idempotent re-runs
DROP USER IF EXISTS 'sanara_app'@'%';
DROP USER IF EXISTS 'sanara_migrator'@'%';
DROP USER IF EXISTS 'sanara_ro'@'%';
DROP USER IF EXISTS 'sanara_backup'@'localhost';
DROP USER IF EXISTS 'sanara_replicator'@'%';

-- 3. Provision Service Accounts with Strong Authentication

-- [Account A] Production PHP Backend Application User
-- Restricted strictly to DML operations and routine execution
CREATE USER 'sanara_app'@'%' 
    IDENTIFIED WITH caching_sha2_password BY 'SanaraApp_SecurePass2026!'
    WITH MAX_USER_CONNECTIONS 300;

GRANT SELECT, INSERT, UPDATE, DELETE, EXECUTE 
    ON `sanara_ecommerce`.* TO 'sanara_app'@'%';

-- [Account B] CI/CD Schema Migration & Maintenance User
-- Granted DDL + DML permissions for running Laravel/Symfony migrations
CREATE USER 'sanara_migrator'@'%' 
    IDENTIFIED WITH caching_sha2_password BY 'SanaraMigrator_Key2026!'
    WITH MAX_USER_CONNECTIONS 20;

GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, ALTER, INDEX, 
      REFERENCES, CREATE VIEW, SHOW VIEW, CREATE ROUTINE, ALTER ROUTINE, 
      TRIGGER, EVENT, LOCK TABLES
    ON `sanara_ecommerce`.* TO 'sanara_migrator'@'%';

-- [Account C] Read-Only Analytics, BI & Read-Replica User
CREATE USER 'sanara_ro'@'%' 
    IDENTIFIED WITH caching_sha2_password BY 'SanaraReadOnly_Report2026!'
    WITH MAX_USER_CONNECTIONS 50;

GRANT SELECT, SHOW VIEW, EXECUTE 
    ON `sanara_ecommerce`.* TO 'sanara_ro'@'%';

-- [Account D] Automated Backup Daemon (Localhost Only)
CREATE USER 'sanara_backup'@'localhost' 
    IDENTIFIED WITH caching_sha2_password BY 'SanaraBackup_LocalSecret2026!'
    WITH MAX_USER_CONNECTIONS 5;

GRANT SELECT, LOCK TABLES, SHOW VIEW, PROCESS, RELOAD, REPLICATION CLIENT, EVENT, TRIGGER
    ON *.* TO 'sanara_backup'@'localhost';

-- [Account E] Binary Log GTID Replication User (for Read Replicas)
CREATE USER 'sanara_replicator'@'%' 
    IDENTIFIED WITH caching_sha2_password BY 'SanaraReplica_NodeSync2026!'
    REQUIRE SSL;

GRANT REPLICATION SLAVE, REPLICATION CLIENT 
    ON *.* TO 'sanara_replicator'@'%';

-- Flush privileges to activate grant tables immediately
FLUSH PRIVILEGES;
