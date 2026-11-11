<#
.SYNOPSIS
  Builds the signed Play Store App Bundle (.aab) of Claro Pulse (Flutter) into releases/, and
  bumps the version code so every upload is an upgrade.

.DESCRIPTION
  Mirrors ClaroPulse/build-release-aab.ps1 (the Kotlin app). This bundle goes to the SAME Play
  Store listing as the Kotlin app: same app ID (in.claroenergy.claropulse), same signing key.
  Farmers who have the Kotlin app get this as a normal update.

  What it does, in order, stopping at the first problem:
    1. Checks the release key is set up (android/key.properties) - an unsigned .aab uploads nowhere.
    2. Runs flutter analyze + flutter test (skip with -SkipChecks).
    3. Builds against the production API with fake data OFF.
    4. Checks the bundle really carries the version asked for and really is signed.
    5. Copies it to releases/ and records the version code in .release-version (git-ignored).

  Version code: one more than the last one this PC built, and never below the Kotlin app's last
  Play Store code (2). Play Console is the real source of truth - if it already has a higher one,
  pass -VersionCode.

.USAGE
  .\build-release-aab.ps1
  .\build-release-aab.ps1 -VersionCode 7            # realign with what Play Console already has
  .\build-release-aab.ps1 -VersionName "2.1.0"      # default is 2.0.<versionCode>

  One-time setup: android/key.properties with the Kotlin app's keystore (see README.md).
#>

param(
    [int]$VersionCode,
    [string]$VersionName,
    [switch]$SkipChecks
)

$ErrorActionPreference = "Stop"
$repoRoot = $PSScriptRoot
Set-Location $repoRoot

. (Join-Path $repoRoot "scripts\flutter-common.ps1")
$flutter = Find-Flutter

# -- 1. Signing check (before the slow build) -----------------------------------------------------
# Same precedence as android/app/build.gradle.kts: key.properties first, then the environment.
$keyPropsPath = Join-Path $repoRoot "android\key.properties"
$keyPropsLines = if (Test-Path $keyPropsPath) { Get-Content $keyPropsPath } else { @() }
function Get-SigningValue([string]$propKey, [string]$envKey) {
    $line = $keyPropsLines | Where-Object { $_ -match "^\s*$propKey\s*=" -and $_ -notmatch '^\s*#' } | Select-Object -First 1
    if ($line) { return ($line -split '=', 2)[1].Trim() }
    return [Environment]::GetEnvironmentVariable($envKey)
}
$storeFile   = Get-SigningValue "storeFile"     "RELEASE_KEYSTORE_PATH"
$storePasswd = Get-SigningValue "storePassword" "RELEASE_KEYSTORE_PASSWORD"
$keyAlias    = Get-SigningValue "keyAlias"      "RELEASE_KEY_ALIAS"
$keyPasswd   = Get-SigningValue "keyPassword"   "RELEASE_KEY_PASSWORD"

$missing = @()
if (-not $storeFile)   { $missing += "storeFile" }
if (-not $storePasswd) { $missing += "storePassword" }
if (-not $keyAlias)    { $missing += "keyAlias" }
if (-not $keyPasswd)   { $missing += "keyPassword" }
if ($missing.Count -gt 0) {
    Write-Error ("Release key not set up: missing $($missing -join ', ') in android\key.properties.`n" +
        "Create android\key.properties with the Kotlin app's keystore (the values are in ClaroPulse\local.properties):`n" +
        "  storeFile=C:/Users/jenac/keystores/claro-pulse-release.jks`n" +
        "  storePassword=...`n  keyAlias=claro-pulse`n  keyPassword=...`n" +
        "It must be the SAME key as the Kotlin app, or Play rejects the upload.")
}
$resolvedStore = if ([System.IO.Path]::IsPathRooted($storeFile)) { $storeFile } else { Join-Path $repoRoot "android\app\$storeFile" }
if (-not (Test-Path $resolvedStore)) {
    Write-Error "Keystore not found at $resolvedStore.`nEvery update MUST be signed with the Kotlin app's key - restore it from your backup."
}
Write-Host "Signing: OK (keystore at $resolvedStore, alias $keyAlias)" -ForegroundColor Green
Write-Host "Backend: $ProdApiBaseUrl (fake data OFF)" -ForegroundColor Cyan

# -- 2. Version -----------------------------------------------------------------------------------
$versionFilePath = Join-Path $repoRoot ".release-version"
$lastVersionCode = Get-LastVersionCode $versionFilePath
$nextVersionCode = if ($PSBoundParameters.ContainsKey('VersionCode')) { $VersionCode } else { $lastVersionCode + 1 }
$nextVersionName = if ($VersionName) { $VersionName } else { "2.0.$nextVersionCode" }
if ($nextVersionCode -le $KotlinLastVersionCode) {
    Write-Warning "versionCode $nextVersionCode is not above the Kotlin app's last Play Store code ($KotlinLastVersionCode). Play will reject it."
}
Write-Host "Version: code $nextVersionCode, name $nextVersionName" -ForegroundColor Cyan
Write-Host "Ctrl-C now if any of that is wrong." -ForegroundColor Yellow
Start-Sleep -Seconds 3

# -- 3. Checks + build ----------------------------------------------------------------------------
& $flutter pub get
if ($LASTEXITCODE -ne 0) { Write-Error "flutter pub get failed - see output above." }

if (-not $SkipChecks) {
    Write-Host "`nflutter analyze..." -ForegroundColor Cyan
    & $flutter analyze
    if ($LASTEXITCODE -ne 0) { Write-Error "flutter analyze found problems - fix them before releasing (or -SkipChecks if you are sure)." }
    Write-Host "`nflutter test..." -ForegroundColor Cyan
    & $flutter test
    if ($LASTEXITCODE -ne 0) { Write-Error "Tests failed - not building a release." }
}

Write-Host "`nBuilding release App Bundle..." -ForegroundColor Cyan
& $flutter build appbundle --release `
    --build-number=$nextVersionCode --build-name=$nextVersionName `
    "--dart-define=MOCK_API=false" "--dart-define=API_BASE_URL=$ProdApiBaseUrl"
if ($LASTEXITCODE -ne 0) {
    Write-Error "Build failed (exit code $LASTEXITCODE) - see output above. versionCode $nextVersionCode was NOT recorded, so the next run tries the same number."
}

$builtAab = Join-Path $repoRoot "build\app\outputs\bundle\release\app-release.aab"
if (-not (Test-Path $builtAab)) { Write-Error "Build reported success but the bundle was not found at:`n  $builtAab" }

# -- 4. Verify version + signature inside the bundle ----------------------------------------------
Add-Type -AssemblyName System.IO.Compression.FileSystem
$zip = [System.IO.Compression.ZipFile]::OpenRead($builtAab)
try {
    $entry = $zip.Entries | Where-Object { $_.FullName -eq "base/manifest/AndroidManifest.xml" }
    if (-not $entry) { Write-Error "Could not read base/manifest/AndroidManifest.xml from the bundle." }
    $reader = New-Object System.IO.StreamReader($entry.Open())
    $manifestText = $reader.ReadToEnd()
    $reader.Dispose()
    $signature = $zip.Entries | Where-Object { $_.FullName -match '^META-INF/.+\.(RSA|DSA|EC)$' } | Select-Object -First 1
} finally {
    $zip.Dispose()
}
if ($manifestText -notmatch [regex]::Escape($nextVersionName)) {
    Write-Error "Version mismatch: asked for $nextVersionName but the bundle does not carry it. Do NOT upload this bundle."
}
if (-not $signature) {
    Write-Error "The bundle is NOT signed (no signature in META-INF). Check android\key.properties. Do NOT upload this bundle."
}
Write-Host "Verified: versionName $nextVersionName, signed ($($signature.FullName))." -ForegroundColor Green

# -- 5. Copy out + record -------------------------------------------------------------------------
$releasesDir = Join-Path $repoRoot "releases"
if (-not (Test-Path $releasesDir)) { New-Item -ItemType Directory -Path $releasesDir | Out-Null }
$timestamp = Get-Date -Format "yyyyMMdd-HHmm"
$outputPath = Join-Path $releasesDir "ClaroPulse-flutter-v$nextVersionCode-$nextVersionName-$timestamp.aab"
Copy-Item $builtAab $outputPath -Force
Set-Content -Path $versionFilePath -Value "$nextVersionCode" -NoNewline

Write-Host "`nDone." -ForegroundColor Green
Write-Host "Bundle ready to upload: $outputPath" -ForegroundColor Green
Write-Host "versionCode $nextVersionCode recorded in .release-version for next time."
Write-Host "`nNext: Play Console -> Claro Pulse -> Testing -> Internal testing -> Create new release -> upload this .aab."
Write-Host "Try it from internal testing on a phone that has the Kotlin app first: it must update in place. Check whether the farmer stays signed in (the Kotlin app's saved login may not carry over)."
