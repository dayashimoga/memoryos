# MemoryOS Report Compiler
[CmdletBinding()]
param()
Write-Host "📊 Generating system audit reports..." -ForegroundColor Cyan
docker compose run --rm builder python3 scripts/verify_readiness.py
Write-Host "✅ Generated reports in artifacts/reports/" -ForegroundColor Green
