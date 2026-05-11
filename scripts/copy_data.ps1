$ErrorActionPreference = "Stop"
$here = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$dst = Join-Path $here "data"
$src = Join-Path $here "..\3\data"
if (-not (Test-Path $src)) {
    $src = Join-Path $here "..\BigDataSpark\data"
}
if (-not (Test-Path $src)) {
    Write-Error "CSV source not found (expected ..\3\data or ..\BigDataSpark\data). Copy MOCK_DATA*.csv into: $dst"
}
New-Item -ItemType Directory -Force -Path $dst | Out-Null
Copy-Item -Force (Join-Path $src "MOCK_DATA*.csv") $dst
Write-Host "Copied to $dst :"
Get-ChildItem $dst -Filter "MOCK_DATA*.csv" | ForEach-Object { $_.Name }
