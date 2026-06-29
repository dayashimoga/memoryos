# MemoryOS Feature Specification Auditor
[CmdletBinding()]
param()
Write-Host "📋 Validating feature registry specifications..." -ForegroundColor Cyan
docker compose run --rm builder python3 scripts/verify_readiness.py
Write-Host "✅ Registry matches requirements." -ForegroundColor Green
