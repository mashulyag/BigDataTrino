#!/bin/sh
# Ручной запуск с хоста (LF). TRUNCATE — только POST в тело запроса (GET часто даёт HTTP 500).
set -e
AUTH="default:${CLICKHOUSE_PASSWORD:-bdtrino_ch}"
BASE="http://localhost:8124"
echo "Truncating bdtrino.mock_data..."
curl -sS -f -u "${AUTH}" -X POST "${BASE}/?database=bdtrino" \
  --data-binary "TRUNCATE TABLE IF EXISTS mock_data"
for f in \
  "MOCK_DATA.csv" \
  "MOCK_DATA (1).csv" \
  "MOCK_DATA (2).csv" \
  "MOCK_DATA (3).csv" \
  "MOCK_DATA (4).csv"
do
  echo "Loading ${f}..."
  curl -sS -f -u "${AUTH}" --data-binary "@./data/${f}" \
    "${BASE}/?database=bdtrino&query=INSERT%20INTO%20mock_data%20FORMAT%20CSVWithNames"
done
echo "Rows:"
curl -sS -f -u "${AUTH}" "${BASE}/?database=bdtrino&query=SELECT%20count()%20FROM%20mock_data"
