# MemoryOS User Journey Smoke Tests
[CmdletBinding()]
param()
Write-Host "💨 Executing user journey E2E smoke tests..." -ForegroundColor Cyan
docker compose run --rm tester
Write-Host "✅ Smoke tests passed!" -ForegroundColor Green
