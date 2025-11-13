#!/bin/bash
# ================================================
# Stop MariaDB (local install under /db1/myserver/mariadb)
# ================================================

MYSQLADMIN="/db1/myserver/mariadb/mariadb_files/bin/mysqladmin"
SOCKET="/db1/myserver/mariadb/run/mysql.sock"
LOG_DIR="/db1/myserver/mariadb/logs"
LOG_FILE="$LOG_DIR/shutdown-$(date +'%Y-%m-%d_%H-%M-%S').log"

mkdir -p "$LOG_DIR"

# --- check if running ---
if ! pgrep -x mysqld > /dev/null; then
  echo "[INFO] MariaDB is not running." | tee -a "$LOG_FILE"
  exit 0
fi

echo "[INFO] Stopping MariaDB..." | tee -a "$LOG_FILE"

# --- prompt for password and stop the server ---
$MYSQLADMIN -u root -p -S "$SOCKET" shutdown >> "$LOG_FILE" 2>&1

# --- verify shutdown ---
sleep 2
if pgrep -x mysqld > /dev/null; then
  echo "[ERROR] MariaDB failed to stop. Check logs: $LOG_FILE" | tee -a "$LOG_FILE"
  exit 1
else
  echo "[SUCCESS] MariaDB stopped successfully." | tee -a "$LOG_FILE"
fi
