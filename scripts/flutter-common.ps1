# Shared by run-on-phone.ps1, build-uat-apk.ps1 and build-release-aab.ps1. Dot-source it.

# Same hosts as the Kotlin app's local.properties. Pulse has no UAT environment (ADR-029):
# only local dev and production.
$ProdApiBaseUrl  = "https://pulse-api.claroenergy.in/app/v1/"
$LocalApiBaseUrl = "http://localhost:3101/app/v1/"

# The Kotlin app's last Play Store versionCode. Play refuses an upload that is not strictly
# higher, so the first Flutter release must be above this even on a fresh checkout with no
# .release-version file yet.
$KotlinLastVersionCode = 2

function Find-Flutter {
    $cmd = Get-Command flutter -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }

    $candidates = @()
    if ($env:FLUTTER_ROOT) { $candidates += (Join-Path $env:FLUTTER_ROOT "bin\flutter.bat") }
    # android/local.properties gets flutter.sdk written by the first `flutter` run on this PC.
    $localProps = Join-Path $PSScriptRoot "..\android\local.properties"
    if (Test-Path $localProps) {
        $line = Get-Content $localProps | Where-Object { $_ -match '^\s*flutter\.sdk\s*=' } | Select-Object -First 1
        if ($line) {
            $sdk = ($line -split '=', 2)[1].Trim() -replace '\\\\', '\' -replace '\\:', ':'
            $candidates += (Join-Path $sdk "bin\flutter.bat")
        }
    }
    $candidates += "C:\flutter\bin\flutter.bat", "C:\src\flutter\bin\flutter.bat",
        "$env:USERPROFILE\flutter\bin\flutter.bat", "$env:LOCALAPPDATA\flutter\bin\flutter.bat"

    foreach ($c in $candidates) { if (Test-Path $c) { return $c } }

    Write-Error ("Flutter was not found on this PC.`n" +
        "Install it (https://docs.flutter.dev/get-started/install/windows/mobile), then either add " +
        "its bin folder to PATH or set FLUTTER_ROOT, and open a new PowerShell window.`n" +
        "Check with: flutter doctor")
}

# The last versionCode this PC uploaded, kept in a git-ignored file like the Kotlin app does.
# Play Console is the real source of truth: pass -VersionCode to realign with it.
function Get-LastVersionCode([string]$versionFile) {
    $last = $KotlinLastVersionCode
    if (Test-Path $versionFile) {
        $raw = (Get-Content $versionFile -Raw).Trim()
        if ($raw -match '^\d+$' -and [int]$raw -gt $last) { $last = [int]$raw }
    }
    return $last
}
