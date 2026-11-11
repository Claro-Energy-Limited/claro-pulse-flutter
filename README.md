# Claro Pulse (Flutter)

The farmer app for Claro Pulse on Android and iOS. It replaces the Kotlin app on the same
Play Store listing (same app ID `in.claroenergy.claropulse`, same signing key).

## One command for each job

Run these from this folder in PowerShell.

| What you want | Command | Output |
|---|---|---|
| Run on your phone or emulator | `.\run-on-phone.ps1` | the app opens on the phone |
| Same, with fake data (no server) | `.\run-on-phone.ps1 -Mock` | |
| Same, against the live API | `.\run-on-phone.ps1 -Prod` | |
| APK to send testers on WhatsApp | `.\build-uat-apk.ps1` (or `-Mock`) | `dist\*.apk` |
| Play Store upload | `.\build-release-aab.ps1` | `releases\*.aab` |
| App Store upload (Mac only) | `./build-ios.sh` | `releases/*.ipa` |

`run-on-phone.ps1` without a flag talks to the API on your own PC (RMS_Monorepo `apps/api`,
port 3101). It runs `adb reverse` so the phone reaches it over the USB cable.

## One-time setup

**Windows (Android)**
1. Install Flutter and Android Studio. `flutter doctor` should show no red items for Android.
2. Create `android\key.properties`. It must point at the **same keystore as the Kotlin app**,
   or Play rejects the upload. The values are in `ClaroPulse\local.properties`:
   ```
   storeFile=C:/Users/jenac/keystores/claro-pulse-release.jks
   storePassword=...
   keyAlias=claro-pulse
   keyPassword=...
   ```
   The file is git-ignored. Never commit it, and keep a backup of the `.jks`: if you lose it,
   you cannot publish updates to this listing.

**Mac (iOS)**: see the header of `build-ios.sh`. You need Xcode, CocoaPods, an Apple Developer
account and the app created in App Store Connect. On its first run the script adds the `ios/`
folder. Commit that folder.

## Version numbers

`build-release-aab.ps1` raises the version code by one on every run and keeps the last one in
`.release-version` (this PC only). It never goes below 3, because the Kotlin app's last Play
Store code was 2. If Play Console already has a higher code, pass it:
`.\build-release-aab.ps1 -VersionCode 9`. iOS keeps its own counter in `.release-version-ios`.

## Releasing to the Play Store

1. `.\build-release-aab.ps1`. It checks the key, runs `flutter analyze` and `flutter test`,
   builds against production with fake data off, then checks the bundle's version and signature.
2. Play Console → Claro Pulse → Testing → Internal testing → Create new release → upload the `.aab`.
3. Install from internal testing on a phone that has the Kotlin app. It must update in place.
   Check whether you are still signed in.
4. Promote the release to Production.
