#!/bin/bash
# ================================================
# Stop MariaDB (local install under /db1/myserver/mariadb)
# - Uses embedded password: Harsh0@server
# - Robust PID detection
# - Graceful shutdown -> TERM -> KILL fallback
# ================================================

set -euo pipefail

BASE="/db1/myserver/mariadb"
MYSQLADMIN="$BASE/mariadb_files/bin/mysqladmin"
SOCKET="$BASE/run/mysql.sock"
PIDFILE="$BASE/run/mysqld.pid"
LOG_DIR="$BASE/logs"
LOG_FILE="$LOG_DIR/shutdown-$(date +'%Y-%m-%d_%H-%M-%S').log"
GRACE_SECONDS=10
KILL_SECONDS=5

# >>> EMBEDDED PASSWORD HERE <<<
DB_PASSWORD='your_password'

mkdir -p "$LOG_DIR"

echo "=== Stop MariaDB: $(date) ===" | tee -a "$LOG_FILE"

# Helper: check if a PID is alive
is_pid_alive() {
  local pid=$1
  if [ -z "$pid" ]; then return 1; fi
  kill -0 "$pid" 2>/dev/null
}

# 1) Try PID file detection
PID=""
if [ -f "$PIDFILE" ]; then
  PID=$(awk '{print $1}' "$PIDFILE" 2>/dev/null || true)
  if is_pid_alive "$PID"; then
    echo "[INFO] Found running MariaDB via PID file ($PIDFILE -> $PID)." | tee -a "$LOG_FILE"
  else
    echo "[WARN] Stale PID file found ($PIDFILE -> $PID). Removing PID file." | tee -a "$LOG_FILE"
    rm -f "$PIDFILE"
    PID=""
  fi
fi

# 2) Fallback to process search
if [ -z "$PID" ]; then
  PID=$(pgrep -o -x mariadbd || true)
  if [ -n "$PID" ] && is_pid_alive "$PID"; then
    echo "[INFO] Detected mariadbd process (PID $PID)." | tee -a "$LOG_FILE"
  else
    PID=$(pgrep -o -x mysqld || true)
    if [ -n "$PID" ] && is_pid_alive "$PID"; then
      echo "[INFO] Detected mysqld process (PID $PID)." | tee -a "$LOG_FILE"
    else
      PID=""
    fi
  fi
fi

if [ -z "$PID" ]; then
  echo "[INFO] MariaDB is not running (no pid/socket detected)." | tee -a "$LOG_FILE"
  if [ -S "$SOCKET" ]; then
    echo "[WARN] Socket exists but no process. Removing stale socket." | tee -a "$LOG_FILE"
    rm -f "$SOCKET"
  fi
  exit 0
fi

echo "[INFO] Attempting graceful shutdown of MariaDB (PID $PID)..." | tee -a "$LOG_FILE"

# === GRACEFUL SHUTDOWN WITH EMBEDDED PASSWORD ===
SHUTDOWN_OK=1
if [ -x "$MYSQLADMIN" ]; then
  echo "[INFO] Using embedded password to shutdown..." | tee -a "$LOG_FILE"

  # -p"$DB_PASSWORD" : attach password directly, safely quoted
  # -S "$SOCKET"     : tell mysqladmin to use the unix socket
  if "$MYSQLADMIN" -u root -p"$DB_PASSWORD" -S "$SOCKET" shutdown >> "$LOG_FILE" 2>&1; then
    SHUTDOWN_OK=0
  else
    SHUTDOWN_OK=1
  fi
else
  echo "[WARN] mysqladmin not found at $MYSQLADMIN" | tee -a "$LOG_FILE"
fi

# Wait for graceful shutdown
if [ "$SHUTDOWN_OK" -eq 0 ]; then
  echo "[INFO] mysqladmin requested shutdown. Waiting $GRACE_SECONDS seconds..." | tee -a "$LOG_FILE"
  for i in $(seq 1 "$GRACE_SECONDS"); do
    if ! is_pid_alive "$PID"; then
      echo "[SUCCESS] MariaDB (PID $PID) stopped gracefully." | tee -a "$LOG_FILE"
      rm -f "$PIDFILE"
      exit 0
    fi
    sleep 1
  done
  echo "[WARN] mysqladmin attempt failed; process still alive." | tee -a "$LOG_FILE"
fi

# Fallback TERM
echo "[INFO] Sending TERM to PID $PID..." | tee -a "$LOG_FILE"
kill -TERM "$PID" 2>/dev/null || true

for i in $(seq 1 "$GRACE_SECONDS"); do
  if ! is_pid_alive "$PID"; then
    echo "[SUCCESS] MariaDB stopped after TERM." | tee -a "$LOG_FILE"
    rm -f "$PIDFILE"
    exit 0
  fi
  sleep 1
done

# Final fallback: KILL
echo "[WARN] PID $PID still alive. Sending KILL." | tee -a "$LOG_FILE"
kill -KILL "$PID" 2>/dev/null || true

for i in $(seq 1 "$KILL_SECONDS"); do
  if ! is_pid_alive "$PID"; then
    echo "[SUCCESS] MariaDB killed and stopped." | tee -a "$LOG_FILE"
    rm -f "$PIDFILE"
    exit 0
  fi
  sleep 1
done

echo "[ERROR] Failed to stop MariaDB. Check: $LOG_FILE" | tee -a "$LOG_FILE"
exit 1
