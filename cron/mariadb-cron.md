# ================================================
# Mariadb Server Cron Job
# Centralized Cron Job Logging to cronlog folder
# Logs stored at: /db1/myserver/mariadb/cronlog/cron-execution.log
# ================================================

# Rotate error.log at 12:01 AM
1 0 * * * echo "[Rotate error.log] $(date)" >> /db1/myserver/mariadb/cronlog/cron-execution.log && mv /db1/myserver/mariadb/logs/error.log /db1/myserver/mariadb/logs/error-$(date -d "yesterday" +%F).log >> /db1/myserver/mariadb/cronlog/cron-execution.log 2>&1

# Rotate general.log at 12:01 AM
1 0 * * * echo "[Rotate general.log] $(date)" >> /db1/myserver/mariadb/cronlog/cron-execution.log && mv /db1/myserver/mariadb/logs/general.log /db1/myserver/mariadb/logs/general-$(date -d "yesterday" +%F).log >> /db1/myserver/mariadb/cronlog/cron-execution.log 2>&1

# Create empty logs after rotation at 12:02 AM
2 0 * * * echo "[Create empty logs] $(date)" >> /db1/myserver/mariadb/cronlog/cron-execution.log && touch /db1/myserver/mariadb/logs/general.log /db1/myserver/mariadb/logs/error.log >> /db1/myserver/mariadb/cronlog/cron-execution.log 2>&1

# Flush Logs at 12:03 AM
3 0 * * * echo "[Flush MariaDB logs] $(date)" >> /db1/myserver/mariadb/cronlog/cron-execution.log && /db1/myserver/mariadb/mariadb_files/bin/mysql -u root -pType_Password_Here -S /db1/myserver/mariadb/run/mysql.sock -e "FLUSH LOGS;" >> /db1/myserver/mariadb/logs/flush-output.log 2>&1

# Delete old startup logs at 12:03 AM
3 0 * * * echo "[Delete old startup logs] $(date)" >> /db1/myserver/mariadb/cronlog/cron-execution.log && find /db1/myserver/mariadb/logs -type f -name 'startup-*.log' -mtime +7 -delete >> /db1/myserver/mariadb/cronlog/cron-execution.log 2>&1

# Delete old general logs at 12:03 AM
3 0 * * * echo "[Delete old general logs] $(date)" >> /db1/myserver/mariadb/cronlog/cron-execution.log && find /db1/myserver/mariadb/logs -type f -name 'general-*.log' -mtime +7 -delete >> /db1/myserver/mariadb/cronlog/cron-execution.log 2>&1

# Delete old error logs at 12:03 AM
3 0 * * * echo "[Delete old error logs] $(date)" >> /db1/myserver/mariadb/cronlog/cron-execution.log && find /db1/myserver/mariadb/logs -type f -name 'error-*.log' -mtime +7 -delete >> /db1/myserver/mariadb/cronlog/cron-execution.log 2>&1

# Copy rotated logs to GitHub folder at 12:04 AM
4 0 * * * echo "[Copy rotated logs to GitHub folder] $(date)" >> /db1/myserver/mariadb/cronlog/cron-execution.log && cp /db1/myserver/mariadb/logs/*-$(date -d "yesterday" +%F).log /db1/github/mariadb/logs/ >> /db1/myserver/mariadb/cronlog/cron-execution.log 2>&1

# Sanitize logs at 12:05 AM
5 0 * * * echo "[Sanitize logs] $(date)" >> /db1/myserver/mariadb/cronlog/cron-execution.log && /db1/myserver/mariadb/scripts/sanitize-logs.sh >> /db1/myserver/mariadb/cronlog/cron-execution.log 2>&1

# Git commit and push at 12:10 AM
10 0 * * * cd /db1/github/mariadb && LOGFILE=/db1/myserver/mariadb/cronlog/cron-execution.log && NOW=$(date +%Y-%m-%d_%H:%M:%S) && echo "[Git push logs to repo] $NOW" >> $LOGFILE && LOCAL=$(git rev-parse @) && REMOTE=$(git rev-parse @{u}) && BASE=$(git merge-base @ @{u}) && if [ "$LOCAL" = "$REMOTE" ]; then echo "[Git] Up-to-date" >> $LOGFILE; elif [ "$LOCAL" = "$BASE" ]; then echo "[Git] Pulling updates..." >> $LOGFILE && git pull origin main --rebase --autostash >> $LOGFILE 2>&1; elif [ "$REMOTE" = "$BASE" ]; then echo "[Git] Local ahead, will push after commit." >> $LOGFILE; else echo "[Git] Diverged. Manual fix needed." >> $LOGFILE && exit 1; fi && git add logs/ && git diff --cached --quiet || git commit -m "Auto-update logs: $NOW" && git push origin main >> $LOGFILE 2>&1

# Delete GitHub logs after push at 12:15 AM
15 0 * * * echo "[Delete GitHub logs after push] $(date)" >> /db1/myserver/mariadb/cronlog/cron-execution.log && rm -f /db1/github/mariadb/logs/*.log >> /db1/myserver/mariadb/cronlog/cron-execution.log 2>&1

# Create MariaDB backup at 12:20 AM
20 0 * * * echo "[Backup database] $(date)" >> /db1/myserver/mariadb/cronlog/cron-execution.log && /db1/myserver/mariadb/scripts/backup-mariadb.sh >> /db1/myserver/mariadb/logs/backup.log 2>&1
