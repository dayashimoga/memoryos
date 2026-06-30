# MemoryOS Packaging Engine
[CmdletBinding()]
param()
Write-Host "🤖 Packaging android APK/AAB distribution binaries via Docker..." -ForegroundColor Cyan
docker compose run --rm flutter-build-android
Write-Host "✅ Android distribution artifacts compiled and saved under artifacts/android/" -ForegroundColor Green
