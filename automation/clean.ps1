# MemoryOS Deep Clean Automation
[CmdletBinding()]
param()
Write-Host "🧹 Deep cleaning MemoryOS docker containers & build targets..." -ForegroundColor Yellow
docker compose down -v
Remove-Item -Recurse -Force target, apps/flutter_app/build, coverage, apps/flutter_app/coverage -ErrorAction SilentlyContinue
Write-Host "✅ Workspace clean complete." -ForegroundColor Green
