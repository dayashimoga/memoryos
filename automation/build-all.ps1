# MemoryOS Cross-Platform Build Automation
[CmdletBinding()]
param()
Write-Host "📦 Starting full cross-platform builds..." -ForegroundColor Cyan
& "$PSScriptRoot/../scripts/build_docker.ps1"
