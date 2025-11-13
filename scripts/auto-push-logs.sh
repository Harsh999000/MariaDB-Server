#!/bin/bash

# === Setup Variables ===
YESTERDAY=$(date +%F)
LOG_SRC="/db1/myserver/mariadb/logs"
DEST_DIR="/db1/github/mariadb/logs"
REPO_DIR="/db1/github/mariadb"

# === Copy and rename logs to flat logs/ folder ===
cp "$LOG_SRC/startup-$YESTERDAY.log" "$DEST_DIR/" 2>/dev/null
cp "$LOG_SRC/error.log" "$DEST_DIR/error-$YESTERDAY.log" 2>/dev/null
cp "$LOG_SRC/general.log" "$DEST_DIR/general-$YESTERDAY.log" 2>/dev/null

# === Git commit and push ===
cd "$REPO_DIR"
git add logs/
git commit -m "Daily log upload: $YESTERDAY"
git push origin main
