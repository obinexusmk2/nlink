# build-windows.ps1
# NexusLink — Windows MSVC build script
# Copyright © 2025 OBINexus Computing
#
# Usage:
#   .\build-windows.ps1                   # Debug build (default)
#   .\build-windows.ps1 -Config Release   # Release build
#   .\build-windows.ps1 -Clean            # Remove build/windows then rebuild (picks best generator)
#   .\build-windows.ps1 -NoBuild          # Configure only (no compile)

[CmdletBinding()]
param(
    [ValidateSet("Debug","Release","RelWithDebInfo","MinSizeRel")]
    [string]$Config = "Debug",

    [switch]$Clean,
    [switch]$NoBuild,
    [switch]$NoTest
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$ProjectRoot = $PSScriptRoot
$BuildDir    = Join-Path $ProjectRoot "build\windows"
$BinPath     = Join-Path $BuildDir "bin\$Config\nlink.exe"

# ── Helpers ───────────────────────────────────────────────────────────────────
function Fail($msg) { Write-Error "ERROR: $msg"; exit 1 }
function Info($msg) { Write-Host "[nlink] $msg" -ForegroundColor Cyan }

# ── Verify cmake is available ─────────────────────────────────────────────────
$cmake = Get-Command cmake -ErrorAction SilentlyContinue
if (-not $cmake) { Fail "cmake not found. Install Visual Studio 2019+ with 'Desktop development with C++'." }

# ── Optional clean ────────────────────────────────────────────────────────────
if ($Clean -and (Test-Path $BuildDir)) {
    Info "Removing $BuildDir ..."
    Remove-Item -Recurse -Force $BuildDir
}

# ── Generator selection ───────────────────────────────────────────────────────
# If an existing CMakeCache.txt is present (and we didn't just delete it),
# CMake will re-use the cached generator automatically — do NOT pass -G.
# Only specify a generator for fresh (no-cache) configurations.
$cacheFile = Join-Path $BuildDir "CMakeCache.txt"
$hasCache  = Test-Path $cacheFile   # false when $Clean was set (directory was removed)

$generator = $null
if (-not $hasCache) {
    # Dynamically discover all "Visual Studio N YYYY" generators from cmake --help,
    # then pick the highest version so VS 18 2026, VS 17 2022, etc. all work.
    $vsGenerators = (& cmake --help 2>&1) |
        Select-String 'Visual Studio \d+ \d+' |
        ForEach-Object { $_.Matches[0].Value.Trim() } |
        Sort-Object -Descending

    $generator = if ($vsGenerators) { $vsGenerators[0] } else { $null }

    if ($generator) {
        Info "Detected generator: $generator"
    } else {
        Info "No Visual Studio generator detected — CMake will use the default generator."
    }
}

# ── Configure ─────────────────────────────────────────────────────────────────
Info "Configuring (config=$Config) ..."
$testFlag = if ($NoTest) { "OFF" } else { "ON" }
$cmakeArgs = @(
    "-S", $ProjectRoot,
    "-B", $BuildDir,
    "-DCMAKE_BUILD_TYPE=$Config",
    "-DBUILD_TESTING=$testFlag"
)

# Only append -G/-A on a fresh (no-cache) configure
if (-not $hasCache -and $generator) {
    $cmakeArgs += @("-G", $generator, "-A", "x64")
}

& cmake @cmakeArgs
if ($LASTEXITCODE -ne 0) { Fail "CMake configure step failed (exit $LASTEXITCODE)." }

# ── Build ─────────────────────────────────────────────────────────────────────
if (-not $NoBuild) {
    Info "Building ..."
    & cmake --build $BuildDir --config $Config --parallel
    if ($LASTEXITCODE -ne 0) { Fail "CMake build step failed (exit $LASTEXITCODE)." }
}

# ── Report ────────────────────────────────────────────────────────────────────
if (Test-Path $BinPath) {
    Info "Build succeeded."
    Info "Binary: $BinPath"
} else {
    # Ninja / NMake generators place the binary directly in bin\ without a config sub-folder
    $altPath = Join-Path $BuildDir "bin\nlink.exe"
    if (Test-Path $altPath) {
        Info "Build succeeded."
        Info "Binary: $altPath"
    } else {
        Write-Warning "Build finished but nlink.exe was not found at expected paths. Check $BuildDir\bin\"
    }
}
