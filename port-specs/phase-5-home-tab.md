# Phase 5 spec: Home tab (device pager, hero card, weather)

Written from the Kotlin source (`ui/home/HomeTabContent.kt`, `ui/home/DevicePager.kt`,
`ui/weather/WeatherWidget.kt`). It describes exactly what the Kotlin app does. Port it
faithfully; flag anything you must change.

Use the existing tokens (`ClaroColors`, `ClaroSpacing`, `ClaroRadius`, `ClaroType`,
`ClaroMotion`) and the phase 4 pieces: `DeviceHeroCard`, `heroCalloutsFor`,
`heroTodaySummaryFor`, `isDeviceRunning`, `DeviceStatusBanners`.

No new packages are required. If you choose a small package for an auto-height
`PageView` (e.g. `expandable_page_view`), say so in your plan.

---

## 1. `lib/ui/home/home_tab.dart` (from `HomeTabContent.kt`)

Replaces `HomeTabPlaceholder`, with the same parameters: `devices`, `devicesError`,
`claims`, `statusById`, `statusErrorById`, `onRetryDevices`, `onPageSettled`,
`onRetryStatus`, `onAddDevice`. `HomeScreen` already wraps it in a vertical
`SingleChildScrollView` with horizontal padding `xl` and a top gap `lg`; keep that.

It shows exactly ONE state, chosen in this order (each replaces the last, never stacks):

| # | condition | shows |
|---|---|---|
| 1 | `devices == null && devicesError == null` | loading: centred mint `CircularProgressIndicator` |
| 2 | `devices == null && devicesError != null` | error state (message = `devicesError`, retry = `onRetryDevices`) |
| 3 | `devices` empty AND `claims` has a claim with `status == 'PENDING'` | pending-claim state (first such claim) |
| 4 | `devices` empty, no pending claim | empty state |
| 5 | one or more devices | device pager |

Why the order matters: a slow network must never look like owning nothing, and a farmer
who has already scanned a device must see that it's pending, not an empty screen again.

Because the Home tab scrolls, the "fill the screen" states (loading, error) can't fill the
viewport height. Show them centred horizontally inside a box of reasonable height (e.g.
280, the same as a device page's loading box) so they don't sit cramped at the top.

### Error state (used for the device list AND a single device's status)
Centred column: `Couldn't load your dashboard` (`title`, `onInk`); gap `xs`; the message
(`body`, `onInkMuted`); gap `lg`; `ClaroPrimaryButton('Try again')` → the given retry.

### Empty state
Column:
1. `WeatherWidget(snapshot: WeatherSnapshot.sample)`
2. gap `xl`
3. Panel: full width, radius `lg`, background `inkPanel`, 1px `borderDark` border,
   padding `xl`; centred column:
   - `NavHomeIcon(size: 40, color: mint)`
   - gap `md`
   - `No devices yet` (`title`, `onInk`)
   - gap `xs`
   - `Scan the QR code on your device to add it to your account.` (`body`, `onInkMuted`, centred)
   - gap `lg`
   - `ClaroPrimaryButton('Add device')` → `onAddDevice`
     (note: `Add device` here, `Add a device` on the Devices tab; both as in Kotlin)

### Pending-claim state
Column:
1. Panel: full width, radius `lg`, background `warnBg` at alpha 0.14, 1px border `warn`
   at alpha 0.4, padding `xl`:
   - `Pending review` (`title`, colour `warn`)
   - gap `xs`
   - `Device {claim.deviceIdentifier} is waiting for your utility's team to approve it. You'll see its data here once that's done.`
     (`body`, `onInk`)
2. gap `xl`
3. `WeatherWidget(snapshot: WeatherSnapshot.sample)`

### Device pager (one or more devices)
`DevicePager(items: devices, onPageSettled: onPageSettled)`; each page:
1. `device.deviceUid` (`subtitle`, `onInkMuted`)
2. gap `md`
3. then one of:
   - status loaded (`statusById[device.deviceId]`): `DeviceHeroCard(kind, isRunning:
     isDeviceRunning(status), callouts: heroCalloutsFor(kind, status), todaySummary:
     heroTodaySummaryFor(kind, status), comingSoon: kind == inverter)`, gap `lg`,
     `DeviceStatusBanners(status: status)`
   - status error (`statusErrorById[device.deviceId]`): the error state, retry =
     `onRetryStatus(device.deviceId)`
   - otherwise: a 280-high box with a centred mint spinner

`kind = DeviceKind.from(device.kind)`.

---

## 2. `lib/ui/home/device_pager.dart` (from `DevicePager.kt`)

Generic: `DevicePager<T>({required List<T> items, required ValueChanged<int> onPageSettled,
required Widget Function(T item) pageBuilder})`.

Behaviour:
- One item per page, swiped horizontally, snapping to whole pages. Spacing `md` between pages.
- **Reports the current page** via `onPageSettled(index)`: once for the initial page (0)
  when first shown, and again each time the current page changes. `HomeScreen` uses this
  to fetch a device's status the first time it is swiped to (it already ignores devices
  it has loaded or failed). Call it after the first frame (e.g. a post-frame callback),
  never during `build`.
- **Height follows the content.** The pager sits inside the vertical scroll of the Home
  tab, so it must NOT have a fixed height that clips the hero card or banners, and must
  not use `Expanded`. Pages differ in height (a pump page is taller than a loading page),
  so size to the current page, e.g. by measuring the current page and animating a
  `SizedBox` height, or an auto-height `PageView` package. Vertical scrolling of the tab
  must still work when the finger starts on the pager.
- **Dots** appear only when there is more than one item (a single device shows no pager
  chrome at all): gap `md` above; a centred row; each dot has 3px horizontal padding;
  active dot 8×8 `mint`, inactive dots 6×6 `borderDark`; all circles. The active dot
  follows the current page.

---

## 3. `lib/ui/weather/weather_widget.dart` (from `WeatherWidget.kt`)

**Not connected to a real weather source, exactly like the Kotlin app.** No weather
provider or location source has been chosen; that's a product decision. It shows fixed
sample data, used only on the empty and pending-claim states.

```dart
class WeatherSnapshot {
  const WeatherSnapshot({required this.condition, required this.temperatureC, required this.note});
  final String condition;
  final int temperatureC;
  final String note;
  static const sample = WeatherSnapshot(
    condition: 'Sunny', temperatureC: 31, note: 'Good conditions for solar generation');
}
```

`WeatherWidget({required WeatherSnapshot snapshot})`: panel, full width, radius `lg`,
background `inkPanel`, 1px `borderDark` border, padding `xl`. Row (vertically centred):
- `_AnimatedSun`, 64×64
- gap `lg`
- column:
  - `{temperatureC}°C` (`ClaroType.displayLg`, `onInk`), e.g. `31°C`
  - `condition` (`subtitle`, `onInkMuted`)
  - gap `xs`
  - `note` (`caption`, colour `mint`)

**`_AnimatedSun`** (`CustomPainter` + a repeating `AnimationController`; dispose it):
- Rotation: 0 → 360° continuously, 12 seconds per turn, linear.
- Pulse: core scale 0.85 ↔ 1.0, 1.6 seconds each way, linear, reversing.
- Drawing (size = the shorter side `m`, centre `c`):
  - 8 rays at angles `rotation + i × 45°`, each a line from radius `0.36m` to `0.48m`,
    stroke width 2, round caps, colour `mint`
  - filled `mint` circle at `c`, radius `0.26m × pulse`
- Slow on purpose: it's ambient decoration, the only decorative animation in the app.

---

## 4. Wiring and clean-up

- `HomeScreen`: use `HomeTab` for the Home tab in place of `HomeTabPlaceholder`.
- Remove `HomeTabPlaceholder` from `placeholder_screens.dart`. Keep `QrScanPlaceholder`
  and `OverlayPlaceholder` (phase 6 replaces them).
- Don't change the mock's device list. To check the empty, pending-claim and
  status-error states, use test-only subclasses of `MockClaroPulseApi`.

## 5. Tests

- `home_tab`: each of the five states, using the order above (including: devices empty
  with a `REJECTED` claim only → empty state, not pending); the error state's retry calls
  the right callback; a device page shows the hero card and `Pump running` when status is
  loaded, a spinner when not, and the error state with `onRetryStatus(deviceId)` on error.
- `device_pager`: `onPageSettled(0)` on first show; swiping (`tester.drag` / `fling`)
  to the second page reports `1`; dots shown for 2 items and absent for 1; the pager
  doesn't clip a tall page (e.g. the full pump page fits).
- `weather_widget`: shows `31°C`, `Sunny`, `Good conditions for solar generation`.
- Update `test/ui/home_screen_test.dart` and `test/widget_test.dart` for the real Home
  tab: e.g. expect `Pump running` instead of the placeholder's `RUNNING · ONLINE`; the
  inverter page is reached by swiping, not a `Next ›` button.

The sun and spinners animate forever, so use `pump(Duration)` rather than
`pumpAndSettle` while they're visible.

## 6. What to check on the emulator

- Home tab: the pump page shows the device ID, the animated hero card, `Pump running`,
  and `Online — updated …`. Two dots under it, the first active.
- Swipe left: the inverter page (inverter image, `Full readings coming soon`, values `—`),
  second dot active. Swipe back: no reload flicker for the pump.
- The whole Home tab still scrolls up and down, including when starting the drag on the card.
