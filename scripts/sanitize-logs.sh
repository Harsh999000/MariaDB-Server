#!/bin/bash
echo "Sanitizing IPs in logs..."

find /db1/github/mariadb/logs/ -type f -name "*.log" | while read file; do
  echo "Masking IPs and ports in: $file"
  # Mask IP address
  sed -i 's/[0-9]\{1,3\}\(\.[0-9]\{1,3\}\)\{3\}/xxx.xxx.xxx.xxx/g' "$file"
  # Mask common port numbers (like 3306, 8080, 5432, etc.)
  # Match format: ":<port>" or "port <port>"
  sed -i 's/port[ :]*[0-9]\{2,5\}/port xxx/gI' "$file"
  sed -i 's/:[0-9]\{2,5\}/:xxx/g' "$file"
done

echo "Done. All IPs and ports masked."
