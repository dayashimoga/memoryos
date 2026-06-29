# MemoryOS Test Automation
[CmdletBinding()]
param()
Write-Host "🧪 Running MemoryOS unit test suite..." -ForegroundColor Cyan
docker compose run --rm tester
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Tests completed successfully!" -ForegroundColor Green
} else {
    Write-Error "❌ Tests failed!"
    exit 1
}
