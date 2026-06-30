# build_docker.ps1 — Fully automated Docker builds for MemoryOS apps.
# Builds: Linux (Rust .so + Flutter), Windows DLL (cross-compile via mingw),
#         Web (Flutter), Android APK+AAB (Rust NDK + Flutter)
# macOS/iOS: Built on Apple host natively (Docker cannot run Xcode)
# Windows EXE: Built on Windows host natively (Docker cannot run MSVC)
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Write-Host "[Docker] Starting fully automated Docker builds for MemoryOS..." -ForegroundColor Cyan

# Step 1: Build Rust Linux Engine + Flutter Linux App
Write-Host "`n[Build] [1/5] Building Linux App (Rust .so + Flutter Linux via Docker)..." -ForegroundColor Yellow
docker compose run --rm flutter-build-linux
if ($LASTEXITCODE -ne 0) { throw "Linux build failed with exit code $LASTEXITCODE" }

# Step 2: Build Rust Windows DLL (Cross-compilation via mingw-w64 in Docker)
Write-Host "`n[Build] [2/5] Building Windows Rust DLL (cross-compile via Docker)..." -ForegroundColor Yellow
docker compose run --rm flutter-build-windows-dll
if ($LASTEXITCODE -ne 0) { throw "Windows DLL cross-compile failed with exit code $LASTEXITCODE" }

# Step 3: Build Flutter Web App
Write-Host "`n[Build] [3/5] Building Web App (Flutter Web via Docker)..." -ForegroundColor Yellow
docker compose run --rm flutter-build-web
if ($LASTEXITCODE -ne 0) { throw "Web build failed with exit code $LASTEXITCODE" }

# Step 4: Build Android App (Rust cargo-ndk all ABIs + Flutter APK+AAB via Docker)
Write-Host "`n[Build] [4/5] Building Android App (Rust NDK + Flutter APK+AAB via Docker)..." -ForegroundColor Yellow
docker compose run --rm flutter-build-android
if ($LASTEXITCODE -ne 0) { throw "Android build failed with exit code $LASTEXITCODE" }

# ── Detect current platform for conditional native builds ──────────────────
$isMacOSPlatform = $false
$isWindowsPlatform = $false

if (Test-Path Variable:IsMacOS) { $isMacOSPlatform = $IsMacOS }
if (Test-Path Variable:IsWindows) { $isWindowsPlatform = $IsWindows }

# Fallback for Windows PowerShell 5.1
if (-not $isMacOSPlatform -and -not $isWindowsPlatform) {
    if ($env:OS -like "*Windows*") {
        $isWindowsPlatform = $true
    } elseif ([System.Environment]::OSVersion.Platform -eq 'Win32NT') {
        $isWindowsPlatform = $true
    }
}

# Step 5: Conditional native builds (macOS/iOS on Apple host, Windows EXE on Windows host)
Write-Host "`n[Build] [5/5] Conditional native builds on local host..." -ForegroundColor Yellow

if ($isMacOSPlatform) {
    $hasFlutter = Get-Command "flutter" -ErrorAction SilentlyContinue
    $hasCargo  = Get-Command "cargo" -ErrorAction SilentlyContinue
    if ($hasFlutter -and $hasCargo) {
        Write-Host "[macOS/iOS] Apple host detected — building native macOS and iOS targets..." -ForegroundColor Cyan

        # macOS Build
        Write-Host "  - Compiling Rust macOS engine..." -ForegroundColor Cyan
        & cargo build --workspace --release
        if ($LASTEXITCODE -ne 0) { throw "Rust macOS build failed" }

        Write-Host "  - Building Flutter macOS App..." -ForegroundColor Cyan
        Push-Location "apps/flutter_app"
        try {
            flutter config --enable-macos-desktop
            flutter clean
            flutter pub get
            flutter build macos --release
            $frameworksDir = "build/macos/Build/Products/Release/memoryos.app/Contents/Frameworks"
            New-Item -ItemType Directory -Force -Path $frameworksDir | Out-Null
            Copy-Item -Path "../../target/release/libcore_engine.dylib" `
                      -Destination "$frameworksDir/libcore_engine.dylib" -Force
            Write-Host "[OK] macOS App built successfully." -ForegroundColor Green
        } catch {
            Write-Error "Failed to build macOS App: $_"
        } finally {
            Pop-Location
        }

        # iOS Build
        Write-Host "  - Adding iOS Rust target and compiling iOS engine..." -ForegroundColor Cyan
        rustup target add aarch64-apple-ios | Out-Null
        & cargo build --workspace --release --target aarch64-apple-ios
        if ($LASTEXITCODE -ne 0) { throw "Rust iOS build failed" }

        Write-Host "  - Building Flutter iOS App (no codesign)..." -ForegroundColor Cyan
        Push-Location "apps/flutter_app"
        try {
            flutter config --enable-ios
            flutter pub get
            flutter build ios --release --no-codesign
            Write-Host "[OK] iOS App built successfully." -ForegroundColor Green
        } catch {
            Write-Error "Failed to build iOS App: $_"
        } finally {
            Pop-Location
        }
    } else {
        Write-Host "[INFO] Flutter or Cargo not found. Skipping native macOS/iOS builds." -ForegroundColor Yellow
    }
} else {
    Write-Host "[INFO] Non-macOS host — skipping macOS and iOS native builds." -ForegroundColor Yellow
    Write-Host "       Use GitHub Actions (macos-latest runner) for macOS/iOS builds." -ForegroundColor Gray
}

if ($isWindowsPlatform) {
    $hasFlutter = Get-Command "flutter" -ErrorAction SilentlyContinue
    if ($hasFlutter) {
        Write-Host "`n[Windows] Windows host detected — building native Windows Flutter app..." -ForegroundColor Cyan
        Push-Location "apps/flutter_app"
        try {
            flutter config --enable-windows-desktop
            flutter pub get
            $env:CMAKE_GENERATOR = "Visual Studio 17 2022"
            flutter build windows --release
            $releaseDir = "build\windows\x64\runner\Release"
            New-Item -ItemType Directory -Force -Path $releaseDir | Out-Null

            # Copy the cross-compiled DLL if available, otherwise the native one
            $nativeDll = "..\..\target\release\core_engine.dll"
            $crossDll  = "..\..\artifacts\windows\core_engine.dll"
            if (Test-Path $crossDll) {
                Copy-Item -Path $crossDll -Destination "$releaseDir\core_engine.dll" -Force
                Write-Host "  [OK] Copied cross-compiled core_engine.dll" -ForegroundColor Green
            } elseif (Test-Path $nativeDll) {
                Copy-Item -Path $nativeDll -Destination "$releaseDir\core_engine.dll" -Force
                Write-Host "  [OK] Copied native core_engine.dll" -ForegroundColor Green
            } else {
                Write-Warning "  core_engine.dll not found — FFI will not be available in Windows build."
            }
            Write-Host "[OK] Windows App built successfully." -ForegroundColor Green
        } catch {
            Write-Warning "Failed to build native Windows Flutter app: $_"
            Write-Host "  The Rust DLL was cross-compiled in step 2 and is available in artifacts/windows/" -ForegroundColor Gray
        } finally {
            Pop-Location
        }
    } else {
        Write-Host "[INFO] Flutter SDK not found on Windows host." -ForegroundColor Yellow
        Write-Host "       Rust DLL is available at: artifacts/windows/core_engine.dll" -ForegroundColor Gray
        Write-Host "       Install Flutter and re-run to build the Windows .exe" -ForegroundColor Gray
    }
}

# ── Validation Gate ─────────────────────────────────────────────────────────
Write-Host "`n[Validate] Validating build outputs..." -ForegroundColor Cyan

function Assert-PathExists {
    param([string]$Path, [string]$Label, [switch]$Warn)
    if (Test-Path $Path) {
        $item = Get-Item $Path
        $size = if ($item.PSIsContainer) {
            (Get-ChildItem -Recurse $Path | Measure-Object -Property Length -Sum).Sum
        } else {
            $item.Length
        }
        $mb = [Math]::Round($size / 1MB, 2)
        Write-Host "  [PASS] $Label => $Path ($mb MB)" -ForegroundColor Green
    } elseif ($Warn) {
        Write-Warning "  [SKIP] $Label not found at: $Path (platform-conditional)"
    } else {
        Write-Error "  [FAIL] $Label NOT found at: $Path"
        exit 1
    }
}

# Core Docker outputs (always expected)
Assert-PathExists "apps/flutter_app/build/linux/x64/release/bundle/memoryos" "Linux Desktop Binary"
Assert-PathExists "apps/flutter_app/build/linux/x64/release/bundle/lib/libcore_engine.so" "Linux Rust FFI Engine"
Assert-PathExists "artifacts/windows/core_engine.dll" "Windows Rust FFI DLL (Docker cross-compiled)"
Assert-PathExists "apps/flutter_app/build/web/index.html" "Flutter Web Bundle"
Assert-PathExists "artifacts/android/memoryos-release.apk" "Android APK"
Assert-PathExists "artifacts/android/memoryos-release.aab" "Android AAB (Play Store Bundle)"

# macOS/iOS (only on Apple host)
if ($isMacOSPlatform -and (Get-Command "flutter" -ErrorAction SilentlyContinue)) {
    Assert-PathExists "apps/flutter_app/build/macos/Build/Products/Release/memoryos.app/Contents/MacOS/memoryos" "macOS App Binary"
    Assert-PathExists "apps/flutter_app/build/macos/Build/Products/Release/memoryos.app/Contents/Frameworks/libcore_engine.dylib" "macOS Rust Engine"
    Assert-PathExists "apps/flutter_app/build/ios/iphoneos/Runner.app" "iOS App Bundle"
} else {
    Write-Host "  [SKIP] macOS/iOS validation (not on Apple host)" -ForegroundColor Gray
}

# Windows EXE (only on Windows host with Flutter)
if ($isWindowsPlatform -and (Get-Command "flutter" -ErrorAction SilentlyContinue)) {
    Assert-PathExists "apps/flutter_app/build/windows/x64/runner/Release/memoryos.exe" "Windows Desktop EXE"
    Assert-PathExists "apps/flutter_app/build/windows/x64/runner/Release/core_engine.dll" "Windows FFI DLL (packaged)"
} else {
    Write-Host "  [SKIP] Windows EXE validation (not on Windows host with Flutter)" -ForegroundColor Gray
}

Write-Host "`n[Success] All platform builds completed and validated!" -ForegroundColor Green
Write-Host @"

Summary of build artifacts:
  Linux  : apps/flutter_app/build/linux/x64/release/bundle/
  Windows: artifacts/windows/core_engine.dll  (+ .exe from Windows host)
  Web    : apps/flutter_app/build/web/
  Android: artifacts/android/memoryos-release.apk + .aab
  macOS  : apps/flutter_app/build/macos/...  (Apple host only)
  iOS    : apps/flutter_app/build/ios/...    (Apple host only)
"@ -ForegroundColor Cyan
