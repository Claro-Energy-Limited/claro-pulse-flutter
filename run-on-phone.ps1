<#
.SYNOPSIS
  Builds Claro Pulse (Flutter) and runs it on the connected Android phone or emulator.

.DESCRIPTION
  Mirrors ClaroPulse/run-on-phone.ps1 (the Kotlin app). Uses `flutter run`, so after it starts you
  can press r in this window to hot reload, R to restart, q to quit.

  Which backend the app talks to:
    (default)  your own PC's API (RMS_Monorepo apps/api on port 3101). `adb reverse` makes the
               phone's own localhost:3101 reach this PC over the USB cable, on a real phone and
               on the emulator alike, so no LAN IP is needed.
    -Mock      built-in fake data, no server at all (good for checking screens).
    -Prod      the live production API. Real farmer accounts: be careful.

.USAGE
  .\run-on-phone.ps1
  .\run-on-phone.ps1 -Mock
  .\run-on-phone.ps1 -Prod
  .\run-on-phone.ps1 -Clean          # wipe the build cache first (slower; use if the build acts odd)
  .\run-on-phone.ps1 -Device emulator-5554   # pick one device when several are connected
#>

param(
    [switch]$Mock,
    [switch]$Prod,
    [switch]$Clean,
    [string]$Device
)

$ErrorActionPreference = "Stop"
$repoRoot = $PSScriptRoot
Set-Location $repoRoot

. (Join-Path $repoRoot "scripts\flutter-common.ps1")
$flutter = Find-Flutter

if ($Mock -and $Prod) { Write-Error "Pick one: -Mock or -Prod, not both." }

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host " Claro Pulse (Flutter): Build & Run on Phone               " -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

# 1. Devices + adb reverse
if (Get-Command adb -ErrorAction SilentlyContinue) {
    $deviceLines = (adb devices | Out-String) -split "`r?`n" |
        Where-Object { $_ -match "\tdevice$" }
    if ($deviceLines.Count -eq 0) {
        Write-Host "WARNING: No connected Android phone or running emulator found." -ForegroundColor Red
        Write-Host "Plug in the phone, turn on USB debugging and accept the prompt on the phone, or start the emulator from Android Studio." -ForegroundColor Red
    } else {
        Write-Host "Found $($deviceLines.Count) device(s)." -ForegroundColor Green
        if (-not $Mock -and -not $Prod) {
            # Does not survive an adb disconnect, so it is re-run every time.
            Write-Host "Forwarding the phone's localhost:3101 to this PC (adb reverse)..." -ForegroundColor Yellow
            if ($Device) { adb -s $Device reverse tcp:3101 tcp:3101 | Out-Null }
            else { foreach ($line in $deviceLines) { adb -s ($line -split "\t")[0] reverse tcp:3101 tcp:3101 | Out-Null } }
        }
    }
} else {
    Write-Host "Note: 'adb' not found on PATH. Flutter will still look for a device; local-API mode needs adb for 'adb reverse'." -ForegroundColor DarkGray
}

# 2. Optional clean
if ($Clean) {
    Write-Host "`n[Clean] flutter clean..." -ForegroundColor Yellow
    & $flutter clean
    if ($LASTEXITCODE -ne 0) { Write-Error "flutter clean failed. Close Android Studio builds that may hold files open, then retry." }
}

# 3. Which backend
$defines = @()
if ($Mock) {
    $defines += "--dart-define=MOCK_API=true"
    Write-Host "`nBackend: built-in fake data (no server)." -ForegroundColor Cyan
} elseif ($Prod) {
    $defines += "--dart-define=MOCK_API=false", "--dart-define=API_BASE_URL=$ProdApiBaseUrl"
    Write-Host "`nBackend: PRODUCTION ($ProdApiBaseUrl). Real farmer data." -ForegroundColor Yellow
} else {
    $defines += "--dart-define=MOCK_API=false", "--dart-define=API_BASE_URL=$LocalApiBaseUrl"
    Write-Host "`nBackend: this PC's API ($LocalApiBaseUrl). Start RMS_Monorepo apps/api first." -ForegroundColor Cyan
}

# 4. Run
Write-Host "`nBuilding and starting the app (first build takes a few minutes)..." -ForegroundColor Yellow
Write-Host "When it is running: r = hot reload, R = restart, q = quit.`n" -ForegroundColor DarkGray
& $flutter pub get
if ($LASTEXITCODE -ne 0) { Write-Error "flutter pub get failed - see output above." }

$runArgs = @("run") + $defines
if ($Device) { $runArgs += @("-d", $Device) }
& $flutter @runArgs
if ($LASTEXITCODE -ne 0) {
    Write-Host "`nERROR: the app did not start. Make sure the phone is plugged in, unlocked and USB debugging is allowed." -ForegroundColor Red
    Write-Host "INSTALL_FAILED_UPDATE_INCOMPATIBLE means the phone has the Play Store / Kotlin build (different key): uninstall Claro Pulse from the phone first." -ForegroundColor Red
    Write-Host "INSTALL_FAILED_USER_RESTRICTED on Xiaomi/MIUI: enable 'Install via USB' in Developer Options." -ForegroundColor Red
    exit 1
}
