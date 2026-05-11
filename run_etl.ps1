$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

if (-not (Test-Path ".\data\MOCK_DATA.csv")) {
    Write-Host "Copying CSV from sibling project (see scripts/copy_data.ps1)..."
    & "$PSScriptRoot\scripts\copy_data.ps1"
}

Write-Host "Trino: star schema (01_star.sql)..."
docker compose exec -T trino trino http://localhost:8080 -f /etc/trino/scripts/01_star.sql
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "Trino: reports (02_reports.sql)..."
docker compose exec -T trino trino http://localhost:8080 -f /etc/trino/scripts/02_reports.sql
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "Done. Checks: README and clickhouse/manual/01_checks.sql"
