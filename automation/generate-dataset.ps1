# MemoryOS Synthetic Dataset Generator
[CmdletBinding()]
param(
    [string]$Scale = "1K"
)
Write-Host "📦 Provisioning synthetic test dataset scale: $Scale..." -ForegroundColor Cyan
docker compose run --rm builder python3 scripts/verify_readiness.py --generate $Scale
Write-Host "✅ Done." -ForegroundColor Green
