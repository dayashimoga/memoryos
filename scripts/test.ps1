# test.ps1 — Windows test runner for MemoryOS.
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Write-Host "🧪 Running MemoryOS tests (Windows)..." -ForegroundColor Cyan

# Rust tests
Write-Host "--- Rust unit tests ---" -ForegroundColor Yellow
cargo test --workspace

# Flutter tests
Write-Host "--- Flutter tests ---" -ForegroundColor Yellow
Push-Location "apps\flutter_app"
flutter pub get
flutter test
Pop-Location

Write-Host ""
Write-Host "✅ All tests passed!" -ForegroundColor Green
