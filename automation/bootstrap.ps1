# MemoryOS Bootstrapping Automation
[CmdletBinding()]
param()
Write-Host "🚀 Bootstrapping MemoryOS Development Container Volumes..." -ForegroundColor Cyan
docker compose pull
docker compose build rust-build flutter-analyze tester
Write-Host "✅ Bootstrap complete! Development containers ready." -ForegroundColor Green
