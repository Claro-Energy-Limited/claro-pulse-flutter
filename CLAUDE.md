# Claro Pulse (Flutter): instructions for Claude Code

## What this project is

A **complete, faithful conversion of the Claro Pulse Android app from Kotlin
(Jetpack Compose) to Flutter.** Claro Pulse is a farmer-facing app: sign in with
phone number + OTP, see your solar pump / inverter devices, their live readings
and activity charts, and add a device by QR scan or manual entry.

- Flutter project (this repo): `C:\Claro-Pulse-Flutter`
- Kotlin original (read-only reference): `C:\Claro-Pulse`
  - Code: `C:\Claro-Pulse\app\src\main\java\in\claroenergy\claropulse\`
  - Resources: `C:\Claro-Pulse\app\src\main\res\`
- App ID: `in.claroenergy.claropulse` (same as the Kotlin app, so the Flutter
  app can replace it on phones). Do not change it.
- Android only. No iOS, web or desktop.

The goal is the same screens, layout, copy, behaviour and edge cases as the
Kotlin app. Not a redesign.

## The user

New to Flutter and Android tooling, on **Windows with PowerShell**. Explain
steps plainly, give exact commands, and say what they should see. They run the
app on an Android emulator ("Medium Phone API 37.0") from Android Studio.

## How to work

1. **Read the Kotlin file(s) first.** Port behaviour exactly, including loading,
   error, empty and "no data" states. Keep the reasoning from the Kotlin doc
   comments in the Dart doc comments (shortened is fine).
2. **Say so explicitly when you deviate** from the Kotlin app (a code comment
   and a line in your summary). Only deviate for a real reason.
3. Before coding a phase, give a **short plan** (files to port, new packages,
   anything unclear) and wait for the go-ahead.
4. After each phase: `flutter analyze` must show **No issues found**, and
   `flutter test` must pass. Then ask the user to run it on the emulator and
   compare with the Kotlin app **before** committing.
5. Commit one phase at a time with a clear message, e.g.
   `feat: devices tab and device detail screen`, then `git push`.

## Code conventions (already in place; follow them)

- **Design tokens only**, never hardcoded values:
  `ClaroColors`, `ClaroSpacing`, `ClaroRadius`, `ClaroMotion`, `ClaroStroke`
  (`lib/app/theme/`), `ClaroType` (type scale).
  - `ClaroColors.inkPanel` and `ClaroColors.inkPanelHigh` are `static final`
    (computed), **not const**. Never use them inside a `const` expression; it
    breaks the build ("Constant evaluation error").
- **Every live number** (readings, totals, OTP digits) uses a `ClaroType.readout*`
  style (JetBrains Mono, tabular figures).
- **Data access only through the `ClaroPulseApi` interface**
  (`lib/core/api/claro_pulse_api.dart`). Two implementations:
  `HttpClaroPulseApi` (real backend) and `MockClaroPulseApi` (fake data).
  If a new screen needs data the mock doesn't provide, extend the mock.
- **`HomeScreen` owns the network calls** for the tabs
  (`lib/ui/home/home_screen.dart`); tab widgets just render the state passed in,
  as in the Kotlin `HomeScreen.kt`.
- Show **no data as a gap / dash (`noData`), never as zero**. Same rule as the Kotlin app.
- Plain `StatefulWidget` + `setState`, no state-management library and no
  navigation library, mirroring the Kotlin app. Overlays are `HomeRoute` values.
- Tests: widget tests with `MockClaroPulseApi(latency: Duration.zero)`, and call
  `FlutterSecureStorage.setMockInitialValues({})` in `setUp`.
  `pumpAndSettle` hangs while an indeterminate spinner or repeating animation is
  visible; use `pump(duration)` in those cases.

## Mock mode

`useMockApi` (`lib/core/config/api_config.dart`) is **on by default in debug
builds**, off in release. Sign in with any 10-digit number and code **123456**.
The mock has one running pump (`mock-pump-1`) and one inverter (`mock-inverter-1`).
Real backend: `--dart-define=MOCK_API=false --dart-define=API_BASE_URL=https://.../app/v1/`.

## Known gotchas (already hit, already fixed)

- **Secure storage can hang on the emulator.** `TokenStore` wraps every call in a
  timeout and the app shows UI before storage finishes. Never `await` storage
  before `runApp`.
- **OTP input:** `ClaroOtpRow` uses a real `TextField` with transparent text over
  painted boxes. Don't hide it with `Opacity(0)`; on the emulator it then
  stopped receiving input.
- **Android build versions:** AGP **8.11.1**, Kotlin **2.2.20**, Gradle **9.3.1**
  (`android/settings.gradle.kts`, `android/gradle/wrapper/gradle-wrapper.properties`).
  Flutter warns that AGP 9 will be required "soon". **Do not migrate to AGP 9**
  (it changes the Android build DSL) without asking first.
- Android Studio sometimes suggests Gradle/AGP upgrades. Flutter manages these;
  don't accept them blindly.
- `android/build/` is generated output and git-ignored. Never commit it.
- Never commit secrets: `.env`, keystores (`*.jks`, `*.keystore`),
  `key.properties`, `google-services.json`, API keys.

## Kotlin → Flutter map

| Kotlin | Flutter | Status |
|---|---|---|
| `ui/theme/*` | `lib/app/theme/*` | Done |
| `data/remote/*`, `data/auth/*`, `di/ServiceLocator.kt` | `lib/core/**` | Done |
| `data/util/RelativeTime.kt` | `lib/core/util/relative_time.dart` | Done |
| `ui/components/*` | `lib/ui/components/*` | Done |
| `ui/icons/ClaroPulseIcons.kt` | `lib/ui/icons/claro_icons.dart` | Done |
| `res/drawable/ic_claro_*.xml` (vectors) | `assets/logos/*.svg` (flutter_svg) | Done |
| `ui/auth/AuthScreen.kt`, `MainActivity.kt` | `lib/ui/auth/auth_screen.dart`, `lib/app/claro_pulse_app.dart` | Done |
| `ui/home/HomeScreen.kt` | `lib/ui/home/home_screen.dart` | Done |
| `ui/complaints/ComplaintsTabContent.kt` | `lib/ui/complaints/complaints_tab.dart` | Done |
| `ui/profile/ProfileTabContent.kt` | `lib/ui/profile/profile_tab.dart` | Done |
| `ui/devices/DeviceKind.kt` | `lib/ui/devices/device_kind.dart` | Done (also holds `noData`) |
| `ui/devices/DeviceMetrics.kt`, `DeviceStatusCard.kt`, `DevicesTabContent.kt`, `DeviceDetailScreen.kt` | `lib/ui/devices/` | **Phase 4** |
| `ui/home/HomeTabContent.kt`, `DevicePager.kt`, `ui/weather/WeatherWidget.kt` | `lib/ui/home/`, `lib/ui/weather/` | **Phase 5** |
| `ui/onboarding/*`, `ui/permission/PermissionRequester.kt` | `lib/ui/onboarding/` | **Phase 6** |
| App label, launcher icon, splash, release build | `android/`, `pubspec.yaml` | **Phase 7** |

**Temporary code to remove as phases land:** `lib/ui/home/placeholder_screens.dart`
(`HomeTabPlaceholder` → phase 5, `DevicesTabPlaceholder` and the device-detail
`OverlayPlaceholder` → phase 4, `QrScanPlaceholder` and the claim/manual-entry
overlays → phase 6). Delete the file once nothing uses it.

## Remaining phases

**Phase 4: Devices tab and device detail.**
Port `DeviceMetrics.kt` (including the hero callout and today-summary builders
used by `DeviceHeroCard`), `DeviceStatusCard.kt`, `DevicesTabContent.kt`,
`DeviceDetailScreen.kt` (activity chart with day/week/month ranges via
`ClaroLineChart`). Wire into `HomeScreen` in place of the placeholders.

**Phase 5: Home tab.**
Port `HomeTabContent.kt`, `DevicePager.kt` (a `PageView`; call
`onPageSettled(index)` when a page settles, as `HomeScreen` already expects) and
`WeatherWidget.kt` (check where its data comes from in the Kotlin code, and
whether mock mode needs a fake source).

**Phase 6: Add a device.**
Port `QrScannerScreen.kt` (use `mobile_scanner`), `ManualDeviceEntryScreen.kt`,
`DeviceClaimScreen.kt`, `PermissionRequester.kt` (use `permission_handler`).
Add the CAMERA permission to `android/app/src/main/AndroidManifest.xml` as the
Kotlin manifest does. After a claim is submitted, return to the Home tab and
reload devices (see `HomeScreen.kt`).

**Phase 7: Finishing.**
App label "Claro Pulse" and the launcher icon from the Kotlin `res/mipmap-*`;
dark launch/splash background (currently white); remove the debug-only
component gallery link and `MOCK` badge from release builds (they're already
`kDebugMode`/mock-only, so verify); release build with `MOCK_API=false`;
release signing config (ask the user for the keystore; never commit it); a
final side-by-side check of every screen against the Kotlin app.
