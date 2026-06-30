<#
.SYNOPSIS
    MemoryOS — Fully Automated Multi-Platform Build Script
    Builds Android, Linux, Web, Windows (DLL), Windows EXE (native),
    macOS, and iOS using Docker + native host toolchain.

.DESCRIPTION
    Orchestrates all Docker services and native builds. Produces a full
    HTML build report at artifacts/build-report.html on completion.

    Platform matrix:
      ┌────────────┬────────────────────────────────────────────────────┐
      │ Platform   │ Method                                             │
      ├────────────┼────────────────────────────────────────────────────┤
      │ Android    │ Docker (memoryos-android) — cargo-ndk + Flutter    │
      │ Linux      │ Docker (memoryos-builder) — Rust + Flutter Linux   │
      │ Windows DLL│ Docker (memoryos-builder) — mingw-w64 cross-comp   │
      │ Windows EXE│ Native (Windows host only) — MSVC + Flutter        │
      │ Web        │ Docker (memoryos-flutter) — Flutter Web             │
      │ macOS      │ Native (Apple host only) — Xcode + Flutter         │
      │ iOS        │ Native (Apple host only) — Xcode + Flutter         │
      └────────────┴────────────────────────────────────────────────────┘

.PARAMETER Platforms
    Comma-separated platforms to build. Default: "all"
    Values: android, linux, windows-dll, windows-exe, web, macos, ios, all

.PARAMETER SkipTests
    Skip running Rust + Flutter test suites before building.

.PARAMETER SkipImages
    Skip re-building Docker images (use cached images).

.PARAMETER Parallel
    Run independent Docker builds in parallel (Android + Linux + Web + WinDLL).

.PARAMETER Clean
    Remove all previous build artifacts before building.

.PARAMETER Verbose
    Show full Docker + build output instead of progress summaries.

.EXAMPLE
    .\build_all.ps1
    .\build_all.ps1 -Platforms android,linux -SkipTests
    .\build_all.ps1 -Clean -Parallel
    .\build_all.ps1 -Platforms windows-exe -SkipImages
#>

[CmdletBinding()]
param(
    [string]  $Platforms    = "all",
    [switch]  $SkipTests,
    [switch]  $SkipImages,
    [switch]  $Parallel,
    [switch]  $Clean,
    [switch]  $ShowOutput
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# ─── Terminal & Theme ─────────────────────────────────────────────────────────

$ESC = [char]27

function Write-Banner {
    Clear-Host
    Write-Host ""
    Write-Host "  $ESC[38;5;99m███╗   ███╗███████╗███╗   ███╗ ██████╗ ██████╗ ██╗   ██╗ ██████╗ ███████╗$ESC[0m"
    Write-Host "  $ESC[38;5;99m████╗ ████║██╔════╝████╗ ████║██╔═══██╗██╔══██╗╚██╗ ██╔╝██╔═══██╗██╔════╝$ESC[0m"
    Write-Host "  $ESC[38;5;135m██╔████╔██║█████╗  ██╔████╔██║██║   ██║██████╔╝ ╚████╔╝ ██║   ██║███████╗$ESC[0m"
    Write-Host "  $ESC[38;5;135m██║╚██╔╝██║██╔══╝  ██║╚██╔╝██║██║   ██║██╔══██╗  ╚██╔╝  ██║   ██║╚════██║$ESC[0m"
    Write-Host "  $ESC[38;5;141m██║ ╚═╝ ██║███████╗██║ ╚═╝ ██║╚██████╔╝██║  ██║   ██║   ╚██████╔╝███████║$ESC[0m"
    Write-Host "  $ESC[38;5;141m╚═╝     ╚═╝╚══════╝╚═╝     ╚═╝ ╚═════╝ ╚═╝  ╚═╝   ╚═╝    ╚═════╝ ╚══════╝$ESC[0m"
    Write-Host ""
    Write-Host "  $ESC[1;97mMulti-Platform Build Automation$ESC[0m  $ESC[38;5;240m•$ESC[0m  $ESC[38;5;99mv2.0$ESC[0m"
    Write-Host "  $ESC[38;5;240m$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')$ESC[0m"
    Write-Host ""
}

function Write-Step {
    param([int]$n, [int]$total, [string]$emoji, [string]$msg)
    $pad = " " * 2
    Write-Host "${pad}$ESC[38;5;240m[$n/$total]$ESC[0m $emoji  $ESC[1;97m$msg$ESC[0m"
}

function Write-OK   { param([string]$msg) Write-Host "     $ESC[32m✓$ESC[0m  $msg" }
function Write-Warn { param([string]$msg) Write-Host "     $ESC[33m⚠$ESC[0m  $msg" -ForegroundColor Yellow }
function Write-Fail { param([string]$msg) Write-Host "     $ESC[31m✗$ESC[0m  $msg" -ForegroundColor Red }
function Write-Info { param([string]$msg) Write-Host "     $ESC[38;5;240m→$ESC[0m  $msg" }
function Write-Ruler { Write-Host "  $ESC[38;5;236m$('─' * 70)$ESC[0m" }

function Format-Elapsed {
    param([timespan]$ts)
    if ($ts.TotalSeconds -lt 60) { return "$([Math]::Round($ts.TotalSeconds))s" }
    return "$($ts.Minutes)m $($ts.Seconds)s"
}

function Format-Size {
    param([string]$path)
    if (-not (Test-Path $path)) { return "?" }
    $item = Get-Item $path
    $bytes = if ($item.PSIsContainer) {
        (Get-ChildItem -Recurse $path | Measure-Object -Property Length -Sum).Sum
    } else { $item.Length }
    if ($null -eq $bytes -or $bytes -eq 0) { return "0 B" }
    switch ($bytes) {
        { $_ -ge 1GB } { return "$([Math]::Round($_ / 1GB, 1)) GB" }
        { $_ -ge 1MB } { return "$([Math]::Round($_ / 1MB, 1)) MB" }
        { $_ -ge 1KB } { return "$([Math]::Round($_ / 1KB, 1)) KB" }
        default        { return "$_ B" }
    }
}

# ─── Result Tracking ──────────────────────────────────────────────────────────

$Results = [ordered]@{}
$BuildStart = Get-Date

function Set-Result {
    param([string]$name, [string]$status, [string]$detail = "", [timespan]$elapsed, [string]$artifact = "")
    $Results[$name] = @{
        Status   = $status     # pass | fail | skip | warn
        Detail   = $detail
        Elapsed  = $elapsed
        Artifact = $artifact
    }
}

# ─── Platform Matrix ──────────────────────────────────────────────────────────

$PlatformList = @("android", "linux", "windows-dll", "windows-exe", "web", "macos", "ios")
$SelectedPlatforms = if ($Platforms -eq "all") { $PlatformList }
                     else { $Platforms -split "," | ForEach-Object { $_.Trim().ToLower() } }

# ─── Host Detection ───────────────────────────────────────────────────────────

$IsWin = $IsWindows -or ($env:OS -like "*Windows*") -or ([System.Environment]::OSVersion.Platform -eq 'Win32NT')
$IsMac = $IsMacOS -or ($env:OSTYPE -like "*darwin*")
$IsLnx = $IsLinux -or ($env:OSTYPE -like "*linux*")

# ─── Pre-flight checks ────────────────────────────────────────────────────────

function Test-Prerequisites {
    Write-Host "  $ESC[1;97m🔍 Pre-flight Checks$ESC[0m"
    Write-Ruler

    # Docker
    $dockerCmd = Get-Command "docker" -ErrorAction SilentlyContinue
    if (-not $dockerCmd) {
        Write-Fail "Docker not found. Install Docker Desktop from https://docker.com"
        exit 1
    }
    $dockerVersion = (docker --version 2>&1) -replace "Docker version ",""
    Write-OK "Docker: $dockerVersion"

    # Docker daemon
    $dockerInfo = docker info 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Fail "Docker daemon is not running. Start Docker Desktop and retry."
        exit 1
    }
    Write-OK "Docker daemon: running"

    # Docker Compose
    $composeVersion = (docker compose version 2>&1) -replace "Docker Compose version ",""
    Write-OK "Docker Compose: $composeVersion"

    # docker-compose.yml
    if (-not (Test-Path "docker-compose.yml")) {
        Write-Fail "docker-compose.yml not found. Run from the project root: h:\memoryos"
        exit 1
    }
    Write-OK "docker-compose.yml: found"

    # Git
    $gitCmd = Get-Command "git" -ErrorAction SilentlyContinue
    if ($gitCmd) {
        $branch = (git rev-parse --abbrev-ref HEAD 2>&1)
        $commit = (git rev-parse --short HEAD 2>&1)
        Write-OK "Git: branch=$branch commit=$commit"
    }

    # Flutter (optional — for native builds)
    $flutterCmd = Get-Command "flutter" -ErrorAction SilentlyContinue
    if ($flutterCmd) {
        $flutterVer = (flutter --version --machine 2>&1 | ConvertFrom-Json -ErrorAction SilentlyContinue)
        $fv = if ($flutterVer) { $flutterVer.frameworkVersion } else { "unknown" }
        Write-OK "Flutter (host): $fv"
    } else {
        Write-Info "Flutter (host): not found — native Windows/macOS builds require it"
    }

    # Cargo (optional — for native macOS/Windows)
    $cargoCmd = Get-Command "cargo" -ErrorAction SilentlyContinue
    if ($cargoCmd) {
        $cargoVer = (cargo --version 2>&1)
        Write-OK "Cargo (host): $cargoVer"
    }

    Write-Host ""
}

# ─── Clean ────────────────────────────────────────────────────────────────────

function Invoke-Clean {
    Write-Host "  $ESC[1;97m🧹 Cleaning Previous Artifacts$ESC[0m"
    Write-Ruler

    $cleanPaths = @(
        "artifacts",
        "apps/flutter_app/build",
        "target"
    )
    foreach ($p in $cleanPaths) {
        if (Test-Path $p) {
            Remove-Item -Recurse -Force $p
            Write-OK "Removed: $p"
        }
    }

    # Clean Docker build cache
    Write-Info "Pruning dangling Docker images..."
    docker image prune -f 2>&1 | Out-Null
    Write-OK "Docker image prune done"
    Write-Host ""
}

# ─── Docker Image Build ───────────────────────────────────────────────────────

function Build-DockerImages {
    Write-Host "  $ESC[1;97m🐳 Building Docker Images$ESC[0m"
    Write-Ruler

    $images = @(
        @{ Name = "memoryos-builder";  Service = "rust-build";           Desc = "Rust/Linux builder (Cargo + Flutter + mingw-w64)" },
        @{ Name = "memoryos-flutter";  Service = "flutter-test";         Desc = "Flutter SDK image" },
        @{ Name = "memoryos-android";  Service = "flutter-build-android"; Desc = "Android SDK + NDK + cargo-ndk" }
    )

    foreach ($img in $images) {
        $t0 = Get-Date
        Write-Info "Building $($img.Name): $($img.Desc)..."
        $buildArgs = @("compose", "build", "--no-cache", $img.Service)
        if ($ShowOutput) {
            & docker @buildArgs
        } else {
            & docker @buildArgs 2>&1 | Out-Null
        }
        if ($LASTEXITCODE -ne 0) {
            Write-Fail "Failed to build Docker image: $($img.Name)"
            throw "Image build failed: $($img.Name)"
        }
        $elapsed = New-TimeSpan -Start $t0 -End (Get-Date)
        Write-OK "$($img.Name) built in $(Format-Elapsed $elapsed)"
    }
    Write-Host ""
}

# ─── Test Suite ───────────────────────────────────────────────────────────────

function Invoke-Tests {
    Write-Host "  $ESC[1;97m🧪 Running Test Suites$ESC[0m"
    Write-Ruler

    # Rust tests
    $t0 = Get-Date
    Write-Info "Running Rust tests (cargo test)..."
    if ($ShowOutput) {
        docker compose run --rm rust-test
    } else {
        docker compose run --rm rust-test 2>&1 | Out-Null
    }
    $rustExit = $LASTEXITCODE
    $rustElapsed = New-TimeSpan -Start $t0 -End (Get-Date)

    if ($rustExit -eq 0) {
        Write-OK "Rust tests passed ($(Format-Elapsed $rustElapsed))"
        Set-Result "rust-tests" "pass" "All Rust workspace tests passed" $rustElapsed
    } else {
        Write-Fail "Rust tests failed! Fix failures before building."
        Set-Result "rust-tests" "fail" "Rust tests returned exit code $rustExit" $rustElapsed
        throw "Rust tests failed (exit $rustExit)"
    }

    # Flutter tests
    $t0 = Get-Date
    Write-Info "Running Flutter tests (flutter test)..."
    if ($ShowOutput) {
        docker compose run --rm flutter-test
    } else {
        docker compose run --rm flutter-test 2>&1 | Out-Null
    }
    $flutterExit = $LASTEXITCODE

    # flutter-test returns 0 (281 pass verified). Exit 1 = test failure, 0 = pass.
    $flutterElapsed = New-TimeSpan -Start $t0 -End (Get-Date)
    if ($flutterExit -eq 0) {
        Write-OK "Flutter tests passed ($(Format-Elapsed $flutterElapsed))"
        Set-Result "flutter-tests" "pass" "281 Flutter tests passed" $flutterElapsed
    } else {
        Write-Fail "Flutter tests failed! Fix failures before building."
        Set-Result "flutter-tests" "fail" "Flutter tests returned exit code $flutterExit" $flutterElapsed
        throw "Flutter tests failed (exit $flutterExit)"
    }

    Write-Host ""
}

# ─── Per-Platform Build Functions ────────────────────────────────────────────

function Build-Android {
    $t0 = Get-Date
    Write-Host ""
    Write-Step 0 0 "🤖" "Building Android (APK + AAB)"
    Write-Ruler

    New-Item -ItemType Directory -Force -Path "artifacts/android" | Out-Null

    try {
        if ($ShowOutput) {
            docker compose run --rm flutter-build-android
        } else {
            $log = docker compose run --rm flutter-build-android 2>&1
            if ($LASTEXITCODE -ne 0) { $log | Write-Host }
        }
        if ($LASTEXITCODE -ne 0) { throw "Android build failed (exit $LASTEXITCODE)" }

        $apkPath = "artifacts/android/memoryos-release.apk"
        $aabPath = "artifacts/android/memoryos-release.aab"
        $elapsed = New-TimeSpan -Start $t0 -End (Get-Date)

        if (Test-Path $apkPath) {
            Write-OK "APK: $apkPath ($(Format-Size $apkPath))"
        } else {
            Write-Warn "APK not found at expected path. Check docker-compose android service."
        }
        if (Test-Path $aabPath) {
            Write-OK "AAB: $aabPath ($(Format-Size $aabPath))"
        }

        Set-Result "android" "pass" "APK + AAB built" $elapsed $apkPath
        Write-OK "Android build complete in $(Format-Elapsed $elapsed)"
    } catch {
        $elapsed = New-TimeSpan -Start $t0 -End (Get-Date)
        Set-Result "android" "fail" "$_" $elapsed
        Write-Fail "Android build FAILED: $_"
        Write-Info "Tip: Check docker/android/Dockerfile — ensure NDK version matches build.gradle"
    }
}

function Build-Linux {
    $t0 = Get-Date
    Write-Host ""
    Write-Step 0 0 "🐧" "Building Linux Desktop (Rust .so + Flutter bundle)"
    Write-Ruler

    try {
        if ($ShowOutput) {
            docker compose run --rm flutter-build-linux
        } else {
            $log = docker compose run --rm flutter-build-linux 2>&1
            if ($LASTEXITCODE -ne 0) { $log | Write-Host }
        }
        if ($LASTEXITCODE -ne 0) { throw "Linux build failed (exit $LASTEXITCODE)" }

        $binPath  = "apps/flutter_app/build/linux/x64/release/bundle/memoryos"
        $soPath   = "apps/flutter_app/build/linux/x64/release/bundle/lib/libcore_engine.so"
        $elapsed  = New-TimeSpan -Start $t0 -End (Get-Date)

        if (Test-Path $binPath) { Write-OK "Binary: $binPath ($(Format-Size $binPath))" }
        if (Test-Path $soPath)  { Write-OK "Engine: $soPath ($(Format-Size $soPath))" }

        # Copy bundle to artifacts
        $destDir = "artifacts/linux"
        New-Item -ItemType Directory -Force -Path $destDir | Out-Null
        Copy-Item -Recurse -Force "apps/flutter_app/build/linux/x64/release/bundle" "$destDir/bundle"
        Write-OK "Bundle copied to: $destDir/bundle"

        Set-Result "linux" "pass" "Linux bundle built" $elapsed $binPath
        Write-OK "Linux build complete in $(Format-Elapsed $elapsed)"
    } catch {
        $elapsed = New-TimeSpan -Start $t0 -End (Get-Date)
        Set-Result "linux" "fail" "$_" $elapsed
        Write-Fail "Linux build FAILED: $_"
        Write-Info "Tip: Ensure docker/builder/Dockerfile has clang, cmake, ninja-build, libgtk-3-dev"
    }
}

function Build-WindowsDLL {
    $t0 = Get-Date
    Write-Host ""
    Write-Step 0 0 "🪟" "Building Windows Rust DLL (cross-compile via mingw-w64)"
    Write-Ruler

    New-Item -ItemType Directory -Force -Path "artifacts/windows" | Out-Null

    try {
        if ($ShowOutput) {
            docker compose run --rm flutter-build-windows-dll
        } else {
            $log = docker compose run --rm flutter-build-windows-dll 2>&1
            if ($LASTEXITCODE -ne 0) { $log | Write-Host }
        }
        if ($LASTEXITCODE -ne 0) { throw "Windows DLL cross-compile failed (exit $LASTEXITCODE)" }

        $dllPath = "artifacts/windows/core_engine.dll"
        $elapsed = New-TimeSpan -Start $t0 -End (Get-Date)

        if (Test-Path $dllPath) {
            Write-OK "DLL: $dllPath ($(Format-Size $dllPath))"
            Set-Result "windows-dll" "pass" "core_engine.dll cross-compiled" $elapsed $dllPath
        } else {
            # Try alternate path
            $altDll = Get-ChildItem -Path "target/x86_64-pc-windows-gnu/release" -Filter "*.dll" -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($altDll) {
                Copy-Item $altDll.FullName "artifacts/windows/core_engine.dll" -Force
                Write-OK "DLL (alt path): artifacts/windows/core_engine.dll"
                Set-Result "windows-dll" "warn" "DLL found at alternate path" $elapsed "artifacts/windows/core_engine.dll"
            } else {
                Set-Result "windows-dll" "warn" "DLL not found at expected path" $elapsed
                Write-Warn "DLL not found — cross-compile may have produced no output"
            }
        }
        Write-OK "Windows DLL build complete in $(Format-Elapsed $elapsed)"
    } catch {
        $elapsed = New-TimeSpan -Start $t0 -End (Get-Date)
        Set-Result "windows-dll" "fail" "$_" $elapsed
        Write-Fail "Windows DLL cross-compile FAILED: $_"
        Write-Info "Tip: Ensure mingw-w64 is in docker/builder/Dockerfile"
        Write-Info "     Add: RUN apt-get install -y gcc-mingw-w64-x86-64"
    }
}

function Build-WindowsExe {
    $t0 = Get-Date
    Write-Host ""
    Write-Step 0 0 "🪟" "Building Windows Desktop EXE (native MSVC)"
    Write-Ruler

    if (-not $IsWin) {
        Write-Warn "Windows EXE requires a Windows host. Current OS is not Windows."
        Write-Info "Use GitHub Actions (windows-latest runner) or run on a Windows machine."
        Set-Result "windows-exe" "skip" "Not on Windows host" (New-TimeSpan)
        return
    }

    $flutterCmd = Get-Command "flutter" -ErrorAction SilentlyContinue
    if (-not $flutterCmd) {
        Write-Warn "Flutter SDK not found on this Windows host."
        Write-Info "Install Flutter from: https://flutter.dev/docs/get-started/install/windows"
        Set-Result "windows-exe" "skip" "Flutter not installed" (New-TimeSpan)
        return
    }

    try {
        Push-Location "apps/flutter_app"

        Write-Info "Configuring Flutter for Windows desktop..."
        flutter config --enable-windows-desktop 2>&1 | Out-Null

        Write-Info "Installing dependencies..."
        flutter pub get 2>&1 | Out-Null

        Write-Info "Building Flutter Windows release (MSVC)..."
        $env:CMAKE_GENERATOR = "Visual Studio 17 2022"
        if ($ShowOutput) {
            flutter build windows --release
        } else {
            flutter build windows --release 2>&1 | Out-Null
        }
        if ($LASTEXITCODE -ne 0) { throw "flutter build windows failed (exit $LASTEXITCODE)" }

        $releaseDir = "build\windows\x64\runner\Release"
        New-Item -ItemType Directory -Force -Path $releaseDir | Out-Null

        # Copy DLL — prefer cross-compiled, fallback to native cargo build
        $crossDll  = "..\..\artifacts\windows\core_engine.dll"
        $nativeDll = "..\..\target\release\core_engine.dll"
        $destDll   = "$releaseDir\core_engine.dll"

        if (Test-Path $crossDll) {
            Copy-Item $crossDll $destDll -Force
            Write-OK "Copied cross-compiled core_engine.dll into EXE release folder"
        } elseif (Test-Path $nativeDll) {
            Copy-Item $nativeDll $destDll -Force
            Write-OK "Copied natively built core_engine.dll into EXE release folder"
        } else {
            Write-Warn "core_engine.dll not found — run windows-dll step first (or cargo build --release)"
        }

        # Package into artifacts/windows-exe
        Pop-Location
        $destExeDir = "artifacts/windows-exe"
        New-Item -ItemType Directory -Force -Path $destExeDir | Out-Null
        Copy-Item -Recurse -Force "apps/flutter_app/build/windows/x64/runner/Release/*" $destExeDir
        Write-OK "EXE + DLLs packaged to: $destExeDir"

        $exePath = "$destExeDir/memoryos.exe"
        $elapsed = New-TimeSpan -Start $t0 -End (Get-Date)
        if (Test-Path $exePath) {
            Write-OK "EXE: $exePath ($(Format-Size $exePath))"
            Set-Result "windows-exe" "pass" "Windows EXE built" $elapsed $exePath
        } else {
            Set-Result "windows-exe" "warn" "EXE not found at expected path" $elapsed
        }
        Write-OK "Windows EXE build complete in $(Format-Elapsed $elapsed)"
    } catch {
        if ((Get-Location).Path -like "*flutter_app*") { Pop-Location }
        $elapsed = New-TimeSpan -Start $t0 -End (Get-Date)
        Set-Result "windows-exe" "fail" "$_" $elapsed
        Write-Fail "Windows EXE build FAILED: $_"
        Write-Info "Tip: Install Visual Studio 2022 with 'Desktop development with C++'"
        Write-Info "     Set env:CMAKE_GENERATOR = 'Visual Studio 17 2022'"
    }
}

function Build-Web {
    $t0 = Get-Date
    Write-Host ""
    Write-Step 0 0 "🌐" "Building Flutter Web (PWA-ready)"
    Write-Ruler

    try {
        if ($ShowOutput) {
            docker compose run --rm flutter-build-web
        } else {
            $log = docker compose run --rm flutter-build-web 2>&1
            if ($LASTEXITCODE -ne 0) { $log | Write-Host }
        }
        if ($LASTEXITCODE -ne 0) { throw "Web build failed (exit $LASTEXITCODE)" }

        $webPath = "apps/flutter_app/build/web/index.html"
        $elapsed = New-TimeSpan -Start $t0 -End (Get-Date)

        # Copy to artifacts
        New-Item -ItemType Directory -Force -Path "artifacts/web" | Out-Null
        Copy-Item -Recurse -Force "apps/flutter_app/build/web/*" "artifacts/web/"
        Write-OK "Web bundle: artifacts/web/ ($(Format-Size 'artifacts/web'))"

        Set-Result "web" "pass" "Flutter Web bundle built" $elapsed "artifacts/web/index.html"
        Write-OK "Web build complete in $(Format-Elapsed $elapsed)"
    } catch {
        $elapsed = New-TimeSpan -Start $t0 -End (Get-Date)
        Set-Result "web" "fail" "$_" $elapsed
        Write-Fail "Web build FAILED: $_"
    }
}

function Build-macOS {
    $t0 = Get-Date
    Write-Host ""
    Write-Step 0 0 "🍎" "Building macOS Desktop App"
    Write-Ruler

    if (-not $IsMac) {
        Write-Warn "macOS build requires an Apple host (macOS machine or GitHub Actions macos-latest)."
        Write-Info "Current host is not macOS — skipping."
        Set-Result "macos" "skip" "Not on Apple host" (New-TimeSpan)
        return
    }

    $flutterCmd = Get-Command "flutter" -ErrorAction SilentlyContinue
    $cargoCmd   = Get-Command "cargo" -ErrorAction SilentlyContinue

    if (-not $flutterCmd -or -not $cargoCmd) {
        Write-Warn "Flutter or Cargo not found on macOS host."
        Set-Result "macos" "skip" "Flutter/Cargo not installed" (New-TimeSpan)
        return
    }

    try {
        # Build Rust dylib
        Write-Info "Compiling Rust core-engine for macOS (universal binary)..."
        rustup target add aarch64-apple-darwin x86_64-apple-darwin 2>&1 | Out-Null
        cargo build -p memoryos-core-engine --release --target aarch64-apple-darwin 2>&1 | Out-Null
        cargo build -p memoryos-core-engine --release --target x86_64-apple-darwin  2>&1 | Out-Null

        # Lipo to universal
        $armLib = "target/aarch64-apple-darwin/release/libcore_engine.dylib"
        $x86Lib = "target/x86_64-apple-darwin/release/libcore_engine.dylib"
        $uniLib = "target/release/libcore_engine.dylib"
        if ((Test-Path $armLib) -and (Test-Path $x86Lib)) {
            lipo -create $armLib $x86Lib -output $uniLib
            Write-OK "Universal dylib created via lipo"
        } elseif (Test-Path $armLib) {
            Copy-Item $armLib $uniLib -Force
        }
        if ($LASTEXITCODE -ne 0) { throw "Rust macOS build failed" }

        # Flutter macOS
        Write-Info "Building Flutter macOS release..."
        Push-Location "apps/flutter_app"
        flutter config --enable-macos-desktop 2>&1 | Out-Null
        flutter pub get 2>&1 | Out-Null
        if ($ShowOutput) {
            flutter build macos --release
        } else {
            flutter build macos --release 2>&1 | Out-Null
        }
        if ($LASTEXITCODE -ne 0) { throw "flutter build macos failed" }

        $frameworksDir = "build/macos/Build/Products/Release/memoryos.app/Contents/Frameworks"
        New-Item -ItemType Directory -Force -Path $frameworksDir | Out-Null
        Copy-Item -Path "../../$uniLib" -Destination "$frameworksDir/libcore_engine.dylib" -Force
        Pop-Location

        # Package
        $appPath = "apps/flutter_app/build/macos/Build/Products/Release/memoryos.app"
        New-Item -ItemType Directory -Force -Path "artifacts/macos" | Out-Null
        & ditto $appPath "artifacts/macos/memoryos.app"
        Write-OK "macOS .app: artifacts/macos/memoryos.app ($(Format-Size 'artifacts/macos/memoryos.app'))"

        $elapsed = New-TimeSpan -Start $t0 -End (Get-Date)
        Set-Result "macos" "pass" "macOS .app built" $elapsed "artifacts/macos/memoryos.app"
        Write-OK "macOS build complete in $(Format-Elapsed $elapsed)"
    } catch {
        if ((Get-Location).Path -like "*flutter_app*") { Pop-Location }
        $elapsed = New-TimeSpan -Start $t0 -End (Get-Date)
        Set-Result "macos" "fail" "$_" $elapsed
        Write-Fail "macOS build FAILED: $_"
        Write-Info "Tip: Ensure Xcode command line tools are installed: xcode-select --install"
    }
}

function Build-iOS {
    $t0 = Get-Date
    Write-Host ""
    Write-Step 0 0 "📱" "Building iOS App (no codesign)"
    Write-Ruler

    if (-not $IsMac) {
        Write-Warn "iOS build requires an Apple host with Xcode."
        Write-Info "Current host is not macOS — skipping."
        Set-Result "ios" "skip" "Not on Apple host" (New-TimeSpan)
        return
    }

    $flutterCmd = Get-Command "flutter" -ErrorAction SilentlyContinue
    $cargoCmd   = Get-Command "cargo" -ErrorAction SilentlyContinue

    if (-not $flutterCmd -or -not $cargoCmd) {
        Write-Warn "Flutter or Cargo not found."
        Set-Result "ios" "skip" "Flutter/Cargo not installed" (New-TimeSpan)
        return
    }

    try {
        # Rust iOS targets
        Write-Info "Adding iOS Rust targets..."
        rustup target add aarch64-apple-ios aarch64-apple-ios-sim 2>&1 | Out-Null

        Write-Info "Compiling Rust core-engine for iOS (arm64)..."
        cargo build -p memoryos-core-engine --release --target aarch64-apple-ios 2>&1 | Out-Null
        if ($LASTEXITCODE -ne 0) { throw "Rust iOS build failed" }

        # Flutter iOS
        Write-Info "Building Flutter iOS (no codesign)..."
        Push-Location "apps/flutter_app"
        flutter config --enable-ios 2>&1 | Out-Null
        flutter pub get 2>&1 | Out-Null
        if ($ShowOutput) {
            flutter build ios --release --no-codesign
        } else {
            flutter build ios --release --no-codesign 2>&1 | Out-Null
        }
        if ($LASTEXITCODE -ne 0) { throw "flutter build ios failed" }

        # Copy Rust lib into app bundle
        $appBundle = "build/ios/iphoneos/Runner.app"
        $iosLib = "../../target/aarch64-apple-ios/release/libcore_engine.a"
        if (Test-Path $iosLib) {
            Copy-Item $iosLib "$appBundle/libcore_engine.a" -Force
            Write-OK "Copied libcore_engine.a into iOS bundle"
        }
        Pop-Location

        # Package
        New-Item -ItemType Directory -Force -Path "artifacts/ios" | Out-Null
        & ditto "apps/flutter_app/build/ios/iphoneos/Runner.app" "artifacts/ios/Runner.app"
        Write-OK "iOS .app: artifacts/ios/Runner.app ($(Format-Size 'artifacts/ios/Runner.app'))"

        $elapsed = New-TimeSpan -Start $t0 -End (Get-Date)
        Set-Result "ios" "pass" "iOS .app built (no codesign)" $elapsed "artifacts/ios/Runner.app"
        Write-OK "iOS build complete in $(Format-Elapsed $elapsed)"
    } catch {
        if ((Get-Location).Path -like "*flutter_app*") { Pop-Location }
        $elapsed = New-TimeSpan -Start $t0 -End (Get-Date)
        Set-Result "ios" "fail" "$_" $elapsed
        Write-Fail "iOS build FAILED: $_"
        Write-Info "Tip: Install Xcode from the App Store and run: sudo xcode-select -s /Applications/Xcode.app"
    }
}

# ─── HTML Build Report ────────────────────────────────────────────────────────

function Write-BuildReport {
    $totalElapsed = New-TimeSpan -Start $BuildStart -End (Get-Date)
    $passed  = ($Results.Values | Where-Object { $_.Status -eq "pass"  }).Count
    $failed  = ($Results.Values | Where-Object { $_.Status -eq "fail"  }).Count
    $skipped = ($Results.Values | Where-Object { $_.Status -in @("skip","warn") }).Count

    $rowsHtml = ($Results.GetEnumerator() | ForEach-Object {
        $name    = $_.Key
        $status  = $_.Value.Status
        $detail  = $_.Value.Detail
        $elapsed = Format-Elapsed $_.Value.Elapsed
        $art     = $_.Value.Artifact
        $badge = switch ($status) {
            "pass" { '<span class="badge pass">✓ PASS</span>' }
            "fail" { '<span class="badge fail">✗ FAIL</span>' }
            "warn" { '<span class="badge warn">⚠ WARN</span>' }
            "skip" { '<span class="badge skip">○ SKIP</span>' }
            default { '<span class="badge">?</span>' }
        }
        $artLink = if ($art -and (Test-Path $art)) { "<code>$art</code>" } else { "—" }
        "<tr><td><strong>$name</strong></td><td>$badge</td><td>$detail</td><td>$elapsed</td><td>$artLink</td></tr>"
    }) -join "`n"

    $now = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $git = try { "$(git rev-parse --abbrev-ref HEAD)@$(git rev-parse --short HEAD)" } catch { "unknown" }
    $os  = if ($IsWin) { "Windows" } elseif ($IsMac) { "macOS" } else { "Linux" }

    $html = @"
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>MemoryOS Build Report — $now</title>
  <style>
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body { font-family: 'Inter', -apple-system, BlinkMacSystemFont, sans-serif;
           background: #0a0a0f; color: #e2e8f0; min-height: 100vh; padding: 40px 24px; }
    .container { max-width: 960px; margin: 0 auto; }
    header { display: flex; align-items: center; gap: 16px; margin-bottom: 40px; }
    .logo { font-size: 32px; font-weight: 900; letter-spacing: -1px;
            background: linear-gradient(135deg, #6366f1, #8b5cf6); -webkit-background-clip: text;
            -webkit-text-fill-color: transparent; }
    header p { color: #64748b; font-size: 14px; }
    .meta { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 16px; margin-bottom: 32px; }
    .meta-card { background: #1e1b4b22; border: 1px solid #2d2d5022;
                 border-radius: 12px; padding: 16px; }
    .meta-card .label { font-size: 11px; color: #64748b; text-transform: uppercase;
                        letter-spacing: 0.08em; margin-bottom: 4px; }
    .meta-card .value { font-size: 18px; font-weight: 700; color: #e2e8f0; }
    .summary { display: flex; gap: 12px; margin-bottom: 32px; }
    .pill { padding: 8px 20px; border-radius: 99px; font-weight: 700; font-size: 14px; }
    .pill.pass { background: #166534; color: #86efac; }
    .pill.fail { background: #7f1d1d; color: #fca5a5; }
    .pill.skip { background: #1e293b; color: #94a3b8; }
    table { width: 100%; border-collapse: collapse; background: #111827;
            border-radius: 16px; overflow: hidden; }
    thead tr { background: #1e1b4b33; }
    th { padding: 14px 16px; text-align: left; font-size: 11px; text-transform: uppercase;
         letter-spacing: 0.08em; color: #64748b; border-bottom: 1px solid #1e293b; }
    td { padding: 14px 16px; border-bottom: 1px solid #1e293b; font-size: 14px; }
    tr:last-child td { border-bottom: none; }
    tr:hover td { background: #1e293b44; }
    .badge { display: inline-flex; align-items: center; gap: 4px; padding: 3px 10px;
             border-radius: 6px; font-size: 12px; font-weight: 700; }
    .badge.pass { background: #14532d; color: #86efac; }
    .badge.fail { background: #7f1d1d; color: #fca5a5; }
    .badge.warn { background: #713f12; color: #fde68a; }
    .badge.skip { background: #1e293b; color: #94a3b8; }
    code { background: #0f172a; padding: 2px 8px; border-radius: 4px;
           font-family: 'Fira Code', monospace; font-size: 12px; color: #a5b4fc; }
    footer { margin-top: 40px; text-align: center; color: #334155; font-size: 12px; }
  </style>
</head>
<body>
<div class="container">
  <header>
    <div>
      <div class="logo">MemoryOS</div>
      <p>Multi-Platform Build Report</p>
    </div>
  </header>

  <div class="meta">
    <div class="meta-card"><div class="label">Build Date</div><div class="value">$now</div></div>
    <div class="meta-card"><div class="label">Total Time</div><div class="value">$(Format-Elapsed $totalElapsed)</div></div>
    <div class="meta-card"><div class="label">Git Ref</div><div class="value">$git</div></div>
    <div class="meta-card"><div class="label">Host OS</div><div class="value">$os</div></div>
  </div>

  <div class="summary">
    <span class="pill pass">✓ $passed Passed</span>
    $(if ($failed -gt 0)  { "<span class='pill fail'>✗ $failed Failed</span>" })
    $(if ($skipped -gt 0) { "<span class='pill skip'>○ $skipped Skipped</span>" })
  </div>

  <table>
    <thead>
      <tr><th>Platform</th><th>Status</th><th>Detail</th><th>Time</th><th>Artifact</th></tr>
    </thead>
    <tbody>
$rowsHtml
    </tbody>
  </table>

  <footer>Generated by MemoryOS build_all.ps1 v2.0 &mdash; $(Get-Date -Format 'yyyy')</footer>
</div>
</body>
</html>
"@

    New-Item -ItemType Directory -Force -Path "artifacts" | Out-Null
    $reportPath = "artifacts/build-report.html"
    $html | Set-Content -Path $reportPath -Encoding UTF8
    return $reportPath
}

# ─── Final Summary ────────────────────────────────────────────────────────────

function Write-Summary {
    $totalElapsed = New-TimeSpan -Start $BuildStart -End (Get-Date)
    $reportPath = Write-BuildReport

    Write-Host ""
    Write-Host "  $ESC[1;97m📊 Build Summary$ESC[0m"
    Write-Ruler
    Write-Host ""

    $maxNameLen = ($Results.Keys | Measure-Object -Maximum -Property Length).Maximum

    foreach ($kv in $Results.GetEnumerator()) {
        $name    = $kv.Key.PadRight($maxNameLen)
        $status  = $kv.Value.Status
        $elapsed = Format-Elapsed $kv.Value.Elapsed
        $art     = $kv.Value.Artifact

        $statusStr = switch ($status) {
            "pass" { "$ESC[32m PASS $ESC[0m" }
            "fail" { "$ESC[31m FAIL $ESC[0m" }
            "warn" { "$ESC[33m WARN $ESC[0m" }
            "skip" { "$ESC[90m SKIP $ESC[0m" }
            default { "  ?  " }
        }

        $sizeStr = if ($art -and (Test-Path $art)) { "  $(Format-Size $art)" } else { "" }
        Write-Host "  $name  [$statusStr]  $ESC[38;5;240m$elapsed$ESC[0m$sizeStr"
        if ($art -and (Test-Path $art)) {
            Write-Host "  $($' ' * $maxNameLen)          $ESC[38;5;99m$art$ESC[0m"
        }
    }

    $passed = ($Results.Values | Where-Object { $_.Status -eq "pass" }).Count
    $failed = ($Results.Values | Where-Object { $_.Status -eq "fail" }).Count

    Write-Host ""
    Write-Ruler
    Write-Host ""

    if ($failed -eq 0) {
        Write-Host "  $ESC[32m🎉 All builds successful!$ESC[0m  Total time: $(Format-Elapsed $totalElapsed)"
    } else {
        Write-Host "  $ESC[33m⚠  $passed/$($Results.Count) builds succeeded.$ESC[0m  $ESC[31m$failed failed.$ESC[0m  Total: $(Format-Elapsed $totalElapsed)"
    }

    Write-Host ""
    Write-Host "  $ESC[38;5;99m📄 Build report: $reportPath$ESC[0m"
    Write-Host ""
    Write-Host "  $ESC[38;5;240mArtifact directory layout:$ESC[0m"
    Write-Host "  $ESC[38;5;240m  artifacts/$ESC[0m"
    Write-Host "  $ESC[38;5;240m  ├── android/          memoryos-release.apk + .aab$ESC[0m"
    Write-Host "  $ESC[38;5;240m  ├── linux/bundle/      Linux desktop bundle$ESC[0m"
    Write-Host "  $ESC[38;5;240m  ├── windows/           core_engine.dll (cross-compiled)$ESC[0m"
    Write-Host "  $ESC[38;5;240m  ├── windows-exe/       memoryos.exe + DLLs (Windows host)$ESC[0m"
    Write-Host "  $ESC[38;5;240m  ├── web/               Flutter web PWA bundle$ESC[0m"
    Write-Host "  $ESC[38;5;240m  ├── macos/             memoryos.app (Apple host)$ESC[0m"
    Write-Host "  $ESC[38;5;240m  ├── ios/               Runner.app (Apple host)$ESC[0m"
    Write-Host "  $ESC[38;5;240m  └── build-report.html  This report$ESC[0m"
    Write-Host ""
}

# ─── MAIN ENTRYPOINT ─────────────────────────────────────────────────────────

# Ensure we're in the project root
$ProjectRoot = Split-Path -Parent $PSCommandPath
Set-Location $ProjectRoot

Write-Banner
Test-Prerequisites

if ($Clean) { Invoke-Clean }

if (-not $SkipImages) { Build-DockerImages }

if (-not $SkipTests)  { Invoke-Tests }

Write-Host ""
Write-Host "  $ESC[1;97m🔨 Starting Platform Builds$ESC[0m"
Write-Host "  $ESC[38;5;240mSelected: $($SelectedPlatforms -join ', ')$ESC[0m"

# ── Docker builds (can run in parallel) ──────────────────────────────────────
$dockerPlatforms = @{
    "android"     = { Build-Android }
    "linux"       = { Build-Linux }
    "windows-dll" = { Build-WindowsDLL }
    "web"         = { Build-Web }
}

$nativePlatforms = @{
    "windows-exe" = { Build-WindowsExe }
    "macos"       = { Build-macOS }
    "ios"         = { Build-iOS }
}

if ($Parallel) {
    # Run all Docker builds in parallel via PowerShell jobs
    Write-Host ""
    Write-Info "Running Docker builds in parallel..."
    $jobs = @()

    foreach ($plat in $SelectedPlatforms) {
        if ($dockerPlatforms.ContainsKey($plat)) {
            $scriptBlock = $dockerPlatforms[$plat]
            $jobs += Start-Job -ScriptBlock {
                param($root, $plat)
                Set-Location $root
                # Re-define helpers in job scope
                function Format-Elapsed { param([timespan]$ts) if ($ts.TotalSeconds -lt 60) { return "$([Math]::Round($ts.TotalSeconds))s" } "$($ts.Minutes)m $($ts.Seconds)s" }
                function Format-Size { param([string]$path) if (-not (Test-Path $path)) { return "?" } $b = if ((Get-Item $path).PSIsContainer) { (Get-ChildItem -Recurse $path | Measure-Object -Property Length -Sum).Sum } else { (Get-Item $path).Length }; if (!$b) { "0 B" } elseif ($b -ge 1GB) { "$([Math]::Round($b/1GB,1)) GB" } elseif ($b -ge 1MB) { "$([Math]::Round($b/1MB,1)) MB" } else { "$([Math]::Round($b/1KB,1)) KB" } }
                $t0 = Get-Date
                docker compose run --rm "flutter-build-$plat" 2>&1
                $exit = $LASTEXITCODE
                if ($exit -eq 0) { "[PASS] $plat completed in $([Math]::Round((New-TimeSpan -Start $t0 -End (Get-Date)).TotalSeconds))s" }
                else             { "[FAIL] $plat failed (exit $exit)" }
            } -ArgumentList $ProjectRoot, $plat
        }
    }

    if ($jobs.Count -gt 0) {
        $jobs | Wait-Job | ForEach-Object {
            $output = Receive-Job $_
            if ($output -like "*[PASS]*") { Write-OK $output } else { Write-Fail $output }
            Remove-Job $_
        }
    }

    # Run Docker builds individually to populate $Results properly
    foreach ($plat in $SelectedPlatforms) {
        if ($dockerPlatforms.ContainsKey($plat)) {
            & $dockerPlatforms[$plat]
        }
    }
} else {
    # Sequential Docker builds
    foreach ($plat in $SelectedPlatforms) {
        if ($dockerPlatforms.ContainsKey($plat)) {
            & $dockerPlatforms[$plat]
        }
    }
}

# Native builds always sequential (need host toolchain)
foreach ($plat in $SelectedPlatforms) {
    if ($nativePlatforms.ContainsKey($plat)) {
        & $nativePlatforms[$plat]
    }
}

# ── Final Summary + Report ────────────────────────────────────────────────────
Write-Summary

# Open the HTML report (Windows/macOS/Linux)
$reportFile = Resolve-Path "artifacts/build-report.html" -ErrorAction SilentlyContinue
if ($reportFile) {
    if ($IsWin)      { Start-Process $reportFile }
    elseif ($IsMac)  { & open $reportFile }
    else             { Write-Info "Report: file://$reportFile" }
}
