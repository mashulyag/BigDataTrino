#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
if [[ ! -f ./data/MOCK_DATA.csv ]]; then
  echo "Copying CSV from ../3/data or ../BigDataSpark/data..."
  bash ./scripts/copy_data.sh
fi
echo "Trino: star schema..."
docker compose exec -T trino trino http://localhost:8080 -f /etc/trino/scripts/01_star.sql
echo "Trino: reports..."
docker compose exec -T trino trino http://localhost:8080 -f /etc/trino/scripts/02_reports.sql
echo "Done."
