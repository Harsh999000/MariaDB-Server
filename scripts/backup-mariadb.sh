#!/bin/bash

# === CONFIG ===
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M")
BACKUP_DIR="/db1/backup/mariadb"
MYSQLDUMP="/db1/myserver/mariadb/mariadb_files/bin/mysqldump"
MYCNF="/db1/myserver/mariadb/config/my.cnf"
USER="root"

# === BACKUP ALL DBs ===
$MYSQLDUMP --defaults-file=$MYCNF --user=$USER --password=your_password --all-databases > "$BACKUP_DIR/all-databases-$TIMESTAMP.sql"

# Log
echo "[INFO] Backup completed: $BACKUP_DIR/all-databases-$TIMESTAMP.sql"
