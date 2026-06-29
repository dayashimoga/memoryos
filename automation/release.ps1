# MemoryOS Release Packaging Orchestration
[CmdletBinding()]
param()
Write-Host "🚀 Triggering final release engineering compilation..." -ForegroundColor Cyan
docker compose run --rm builder python3 scripts/verify_readiness.py
Write-Host "✅ Release Readiness Reports stored under artifacts/reports/" -ForegroundColor Green
