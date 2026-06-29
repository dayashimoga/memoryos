# MemoryOS Quality Gates Enforcement
[CmdletBinding()]
param()
Write-Host "🛡️ Evaluating MemoryOS release quality gates..." -ForegroundColor Cyan
docker compose run --rm rust-check
docker compose run --rm flutter-analyze
docker compose run --rm tester
if ($LASTEXITCODE -eq 0) {
    Write-Host "🟩 QUALITY GATE PASSED: All compliance metrics satisfied." -ForegroundColor Green
} else {
    Write-Error "🟥 QUALITY GATE FAILED: Code base fails lints or tests."
    exit 1
}
