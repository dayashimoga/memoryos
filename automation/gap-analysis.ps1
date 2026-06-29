# MemoryOS Gap Analysis Runner
[CmdletBinding()]
param()
Write-Host "🔍 Checking unimplemented feature gaps..." -ForegroundColor Cyan
docker compose run --rm builder python3 scripts/verify_readiness.py
Write-Host "✅ Report updated: artifacts/reports/feature-gap-analysis.html" -ForegroundColor Green
