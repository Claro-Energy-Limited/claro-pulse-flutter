<#
.SYNOPSIS
  Builds a Claro Pulse (Flutter) APK to share with testers over WhatsApp/Drive, into dist/.

.DESCRIPTION
  Mirrors ClaroPulse/build-uat-apk.ps1 (the Kotlin app). Pulse has no UAT backend (ADR-029), so a
  tester's phone can only reach production, or fake data. Default is production.

  The APK is signed with this PC's debug key, like the Kotlin script, so anyone can install it with
  "Install unknown apps" on. It cannot be installed over a Play Store copy of Claro Pulse (different
  key): the tester has to uninstall that first.

  A debug build is large and noticeably slower than the store build. Judge speed on the .aab from
  build-release-aab.ps1 (via Play internal testing), not on this APK.

.USAGE
  .\build-uat-apk.ps1                 # real production API
  .\build-uat-apk.ps1 -Mock           # fake data, no server (for showing the screens)
  .\build-uat-apk.ps1 -ApiBaseUrl http://192.168.1.20:3101/app/v1/   # a PC on the same Wi-Fi
#>

param(
    [switch]$Mock,
    [string]$ApiBaseUrl
)

$ErrorActionPreference = "Stop"
$repoRoot = $PSScriptRoot
Set-Location $repoRoot

. (Join-Path $repoRoot "scripts\flutter-common.ps1")
$flutter = Find-Flutter

if ($Mock) {
    $defines = @("--dart-define=MOCK_API=true")
    $label = "mock"
    Write-Host "Backend: built-in fake data (no server)." -ForegroundColor Cyan
} else {
    if (-not $ApiBaseUrl) { $ApiBaseUrl = $ProdApiBaseUrl }
    if ($ApiBaseUrl -notmatch '/app/v1/$') {
        Write-Error "API base URL must end in /app/v1/ (got $ApiBaseUrl)."
    }
    $defines = @("--dart-define=MOCK_API=false", "--dart-define=API_BASE_URL=$ApiBaseUrl")
    $label = if ($ApiBaseUrl -eq $ProdApiBaseUrl) { "prod" } else { "custom" }
    Write-Host "Backend: $ApiBaseUrl" -ForegroundColor Cyan
    if ($ApiBaseUrl -eq $ProdApiBaseUrl) {
        Write-Warning "This APK talks to PRODUCTION. Testers sign in with real farmer accounts."
        Start-Sleep -Seconds 3
    } elseif ($ApiBaseUrl -match 'localhost|10\.0\.2\.2') {
        Write-Warning "localhost only works on a phone plugged into THIS PC with 'adb reverse tcp:3101 tcp:3101'. Other testers' phones cannot reach it."
        Start-Sleep -Seconds 3
    }
}

Write-Host "`nBuilding debug APK (flutter build apk --debug)..." -ForegroundColor Cyan
& $flutter pub get
if ($LASTEXITCODE -ne 0) { Write-Error "flutter pub get failed - see output above." }
& $flutter build apk --debug @defines
if ($LASTEXITCODE -ne 0) { Write-Error "Build failed (exit code $LASTEXITCODE) - see output above." }

$builtApk = Join-Path $repoRoot "build\app\outputs\flutter-apk\app-debug.apk"
if (-not (Test-Path $builtApk)) {
    Write-Error "Build reported success but the APK was not found at:`n  $builtApk"
}

$distDir = Join-Path $repoRoot "dist"
if (-not (Test-Path $distDir)) { New-Item -ItemType Directory -Path $distDir | Out-Null }
$timestamp = Get-Date -Format "yyyyMMdd-HHmm"
$outputPath = Join-Path $distDir "ClaroPulse-flutter-$label-$timestamp.apk"
Copy-Item $builtApk $outputPath -Force

Write-Host "`nDone." -ForegroundColor Green
Write-Host "APK ready to share: $outputPath" -ForegroundColor Green
Write-Host "`nTesters: turn on 'Install unknown apps' for WhatsApp/Drive/Files, and uninstall any Play Store Claro Pulse first."
