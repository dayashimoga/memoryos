# MemoryOS Performance Benchmarks
[CmdletBinding()]
param()
Write-Host "📊 Running Performance benchmarks & latencies verification..." -ForegroundColor Cyan
docker compose run --rm builder python3 scripts/verify_readiness.py
Write-Host "✅ Benchmarks compiled under artifacts/reports/performance-report.md" -ForegroundColor Green
