# build.ps1 — Windows build script for MemoryOS.
param([string]$Target = "debug")

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Write-Host "🔨 Building MemoryOS ($Target)..." -ForegroundColor Cyan

if ($Target -eq "release") {
    cargo build --workspace --release
    Push-Location "apps\flutter_app"
    flutter build windows --release
    Pop-Location
} else {
    cargo build --workspace
}

Write-Host ""
Write-Host "✅ Build complete!" -ForegroundColor Green
