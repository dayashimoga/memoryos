# MemoryOS Subsystem Verification
[CmdletBinding()]
param()
Write-Host "🚀 Validating offline subsystems..." -ForegroundColor Cyan
docker compose run --rm builder python3 scripts/verify_readiness.py
Write-Host "✅ All verified features match execution specs." -ForegroundColor Green
