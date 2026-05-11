#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DST="$ROOT/data"
SRC1="$ROOT/../3/data"
SRC2="$ROOT/../BigDataSpark/data"
mkdir -p "$DST"
if [[ -d "$SRC1" ]]; then
  cp -f "$SRC1"/MOCK_DATA*.csv "$DST/"
elif [[ -d "$SRC2" ]]; then
  cp -f "$SRC2"/MOCK_DATA*.csv "$DST/"
else
  echo "Expected CSV in $SRC1 or $SRC2" >&2
  exit 1
fi
ls -1 "$DST"/MOCK_DATA*.csv
