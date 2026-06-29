# MemoryOS Code Coverage Compiler
[CmdletBinding()]
param()
Write-Host "📊 Running coverage verification suite..." -ForegroundColor Cyan
docker compose run --rm flutter-test
Write-Host "✅ Coverage metrics generated." -ForegroundColor Green
