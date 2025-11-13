#!/bin/bash
# ================================================
# Start MariaDB (local install under /db1/myserver/mariadb)
# - Robust readiness check (socket+port and/or mysqladmin ping)
# - Clear success/failure reporting
# ================================================

set -u  # treat unset vars as error
# (intentionally not using `set -e` so we can probe commands and handle failures gracefully)
set -o pipefail

BASE="/db1/myserver/mariadb"
CNF="$BASE/config/my.cnf"
LOG_DIR="$BASE/logs"
RUN_DIR="$BASE/run"
SOCKET="$RUN_DIR/mysql.sock"
ERROR_LOG="$LOG_DIR/error.log"
LOG_FILE="$LOG_DIR/startup-$(date +'%Y-%m-%d_%H-%M-%S').log"

MYSQLADMIN="$BASE/mariadb_files/bin/mysqladmin"
MYSQLD_SAFE="$BASE/mariadb_files/bin/mysqld_safe"

mkdir -p "$LOG_DIR" "$RUN_DIR" "$BASE/tmp"

# --- already running? ---
if pgrep -x mariadbd >/dev/null || pgrep -x mysqld >/dev/null; then
  echo "[INFO] MariaDB already running." | tee -a "$LOG_FILE"
  exit 0
fi

echo "[INFO] Starting MariaDB with $CNF ..." | tee -a "$LOG_FILE"

# Start in background and log output
# mysqld_safe keeps supervising, mariadbd becomes the server
"$MYSQLD_SAFE" --defaults-file="$CNF" >> "$LOG_FILE" 2>&1 &

# --- readiness function ---
is_up() {
  # 1) Try mysqladmin ping WITHOUT password to avoid hanging;
  #    if unix_socket auth is enabled for root, this succeeds.
  #    We silence output; only return code matters.
  if "$MYSQLADMIN" --protocol=SOCKET -u root -S "$SOCKET" ping >/dev/null 2>&1; then
    return 0
  fi

  # 2) If ping fails (e.g., root requires password), confirm socket + port 3306 are live
  if [ -S "$SOCKET" ] && ss -ltnp 2>/dev/null | grep -qE 'LISTEN\s+0\s+.*:3306.*\((\"mariadbd\"|\"mysqld\")'; then
    return 0
  fi

  return 1
}

# --- wait up to 30 seconds for readiness ---
for i in $(seq 1 30); do
  if is_up; then
    echo "[OK] MariaDB is ready (after ${i}s)." | tee -a "$LOG_FILE"
    exit 0
  fi
  sleep 1
done

# --- not ready: print helpful diagnostics and fail ---
echo "[ERROR] MariaDB did not become ready within 30s. See logs for details:" | tee -a "$LOG_FILE"
echo "  - Startup log: $LOG_FILE" | tee -a "$LOG_FILE"
echo "  - Error log:   $ERROR_LOG" | tee -a "$LOG_FILE"
if [ -f "$ERROR_LOG" ]; then
  echo "----- tail -n 60 $ERROR_LOG -----" | tee -a "$LOG_FILE"
  tail -n 60 "$ERROR_LOG" | sed 's/^/[error.log] /' | tee -a "$LOG_FILE"
fi
exit 1
