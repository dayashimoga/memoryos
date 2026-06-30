<#
.SYNOPSIS
    MemoryOS — Legacy Docker Build Redirector
    Forwards execution to the unified, robust build_all.ps1 script.
#>

[CmdletBinding(KeepBoundParameters=$true)]
param(
    [string]  $Platforms    = "all",
    [switch]  $SkipTests,
    [switch]  $SkipImages,
    [switch]  $Parallel,
    [switch]  $Clean,
    [switch]  $ShowOutput
)

$targetScript = Join-Path $PSScriptRoot "build_all.ps1"
Write-Host "[Redirect] Delegating build process to: build_all.ps1..." -ForegroundColor Gray
& $targetScript @PSBoundParameters
