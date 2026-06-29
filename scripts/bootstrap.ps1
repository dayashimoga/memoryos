# bootstrap.ps1 — Windows bootstrap script for MemoryOS development.
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Write-Host "🚀 MemoryOS Bootstrap (Windows)" -ForegroundColor Cyan
Write-Host "================================="

# Check Docker
if (-not (Get-Command "docker" -ErrorAction SilentlyContinue)) {
    Write-Error "Docker not found. Install Docker Desktop from https://docker.com"
    exit 1
}

# Check Git
if (-not (Get-Command "git" -ErrorAction SilentlyContinue)) {
    Write-Error "Git not found. Install from https://git-scm.com"
    exit 1
}

Write-Host "✅ Prerequisites OK" -ForegroundColor Green

Write-Host "🐳 Building Docker images..." -ForegroundColor Yellow
docker compose build

Write-Host ""
Write-Host "✅ Bootstrap complete!" -ForegroundColor Green
Write-Host ""
Write-Host "Run: docker compose up"
Write-Host "Docs: http://localhost:8000"
Write-Host "App:  http://localhost:3000"
