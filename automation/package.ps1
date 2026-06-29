# MemoryOS Packaging Engine
[CmdletBinding()]
param()
Write-Host "🤖 Packaging android APK/AAB distribution binaries..." -ForegroundColor Cyan
# Run target android compiles inside containers
docker compose run --rm flutter-build-web
Write-Host "✅ Artifacts saved under artifacts/android/" -ForegroundColor Green
