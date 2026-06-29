# MemoryOS Build Automation
[CmdletBinding()]
param()
Write-Host "🔨 Compiling MemoryOS Workspace (Rust & Flutter)..." -ForegroundColor Cyan
docker compose run --rm rust-build
docker compose run --rm flutter-build-web
Write-Host "✅ Build complete!" -ForegroundColor Green
