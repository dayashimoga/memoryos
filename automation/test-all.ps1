# MemoryOS Extended Test Suite
[CmdletBinding()]
param()
Write-Host "🚀 Running full automated verification suite (Rust + Flutter)..." -ForegroundColor Cyan
docker compose run --rm tester
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Unified test suite passes cleanly." -ForegroundColor Green
} else {
    Write-Error "❌ Verification test run failed."
    exit 1
}
