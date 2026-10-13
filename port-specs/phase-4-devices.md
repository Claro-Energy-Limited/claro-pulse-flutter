# Phase 4 spec: Devices tab and device detail

Written from the Kotlin source (`ui/devices/DeviceMetrics.kt`, `DeviceStatusCard.kt`,
`DevicesTabContent.kt`, `DeviceDetailScreen.kt`). It describes exactly what the Kotlin app
does. Port it faithfully; flag anything you must change.

All colours, spacing, radii and type come from the existing tokens (`ClaroColors`,
`ClaroSpacing`, `ClaroRadius`, `ClaroType`). Remember `ClaroColors.inkPanel` and
`inkPanelHigh` are not const.

New package: `intl` (for date labels). `flutter pub add intl`.

---

## 1. `lib/ui/devices/device_metrics.dart` (from `DeviceMetrics.kt`)

The one place that turns a `DeviceStatus` + `DeviceKind` into what `DeviceHeroCard` shows.
Home (phase 5) and the detail screen both use it, so a device can never show two different
sets of numbers.

`noData` (`'—'`) already exists in `lib/ui/devices/device_kind.dart`; keep using it.

### `List<HeroCallout> heroCalloutsFor(DeviceKind kind, DeviceStatus? status)`
Always exactly 4, in order top-left, top-right, bottom-left, bottom-right.

**Pump** (values from `status.live`; `null` status or field → `noData`):

| label | value | unit |
|---|---|---|
| `Solar` | `solarPowerKw` to 1 decimal (`5.24` → `"5.2"`) | `kW` |
| `Flow` | `flowRateLpm` to 0 decimals (`288.4` → `"288"`) | `LPM` |
| `Motor` | `motorSpeedRpm` to 0 decimals | `RPM` |
| `Head` | `workingHeadM` to 1 decimal | `m` |

Motor power is deliberately NOT shown (its unit is unconfirmed on the server).

**Inverter**: real labels, every value `noData` (no inverter telemetry exists yet; never
fake numbers): `Solar`/`kW`, `Grid`/`kW`, `Battery`/`%`, `Load`/`kW`.

### `List<HeroMetric> heroTodaySummaryFor(DeviceKind kind, DeviceStatus? status)`
**Pump**: `Run Hours Today` = `today.runHours` 1 decimal, unit `hrs`;
`Energy Today` = `today.energyKwh` 1 decimal, unit `kWh`. Missing → `noData`.
**Inverter**: empty list.

### `enum ActivitySeries`
`runHours('Run Hours', 'hrs')`, `energy('Energy', 'kWh')`, `water('Water', 'L')`,
with `double? valueOf(ActivityPoint p)` returning `runHours` / `energyKwh` / `waterLiters`.

### `List<double?> activityChartValues(List<ActivityPoint> points, ActivitySeries series)`
Maps each point through `series.valueOf`. Nulls stay null (they draw as gaps).

### `List<String> activityChartLabels(List<ActivityPoint> points, ActivityRange range)`
- Empty points → `[]`.
- Exactly 3 labels at indices `0`, `points.length ~/ 2`, `points.length - 1`
  (just `[0]` if there is one point; remove duplicate indices).
- Parse `bucketStart` with `parseActivityBucketStart`, convert to **local time**, format
  with `intl` `DateFormat(pattern, 'en_US')`:
  - day: `'h a'` → `"6 AM"`
  - week: `'EEE'` → `"Mon"`
  - month: `'MMM d'` → `"Sep 10"`
- Unparseable → `""` for that label.

---

## 2. `lib/ui/devices/device_status_banners.dart` (from `DeviceStatusCard.kt`)

Everything about a status that is NOT a "how much" number: is it running, is anything
wrong, how fresh is this. Shared by Home and Detail.

### `bool isDeviceRunning(DeviceStatus? status)` → `status?.runStatus == 'RUNNING'`

### `DeviceStatusBanners({required DeviceStatus status})`
Column:
1. `_RunStatusBanner`
2. if `status.faultText != null`: gap `md`, then `_FaultBanner(faultText)`
3. if `protections.dryRun || protections.waterLevelLow`: gap `md`, then `_ProtectionsBanner`
4. gap `lg`, then `ClaroFreshnessStamp(text: connectionLabel(status), isLive: connectionStatus == 'ONLINE')`

**`_RunStatusBanner`**: full width; radius `lg`; background `inkPanel`; 1px `borderDark`
border; padding `xl`. Row: a 14×14 circle in the status colour, gap `md`, label in
`ClaroType.title`, colour `onInk`.

| runStatus | label | dot colour |
|---|---|---|
| `RUNNING` | `Pump running` | `mint` |
| `STOPPED` | `Pump stopped` | `onInkMuted` |
| anything else | `Status unknown` | `onInkMuted` |

**`_FaultBanner`**: full width; radius `md`; background `faultBg` at alpha 0.14;
1px border `fault` at alpha 0.4; padding `md`. Row: `Icons.warning` 18 `fault`, gap `sm`,
the fault text in `ClaroType.body`, colour `fault` (wrap if long: use `Expanded`).

**`_ProtectionsBanner`**: same shape with `warnBg` 0.14 / `warn` 0.4 / icon and text `warn`.
Text, exactly:
- dryRun AND waterLevelLow → `Dry-run and low water level protection active`
- dryRun only → `Dry-run protection active — pump paused to avoid damage`
- waterLevelLow only → `Low water level protection active`

**`connectionLabel(status)`** (uses `formatRelativeTime`):
- `ONLINE`: `Online — updated {relative}`, or just `Online` if `lastReportedAt` is null
- `NEVER_REPORTED`: `Never reported in yet`
- anything else: `Offline — last seen {relative}`, or just `Offline` if null

The dashes in these strings are em dashes (`—`), as in the Kotlin app.

---

## 3. `lib/ui/devices/devices_tab.dart` (from `DevicesTabContent.kt`)

Replaces `DevicesTabPlaceholder`. Same parameters:
`devices`, `isLoading`, `error`, `onRetry`, `onDeviceTap`, `onAddDevice`.

Layout: horizontal padding `xl`; gap `lg` at top; header row: `Your devices`
(`ClaroType.title`, `onInk`, expanded) + add button; gap `lg`; then exactly one state:

| condition (checked in this order) | shows |
|---|---|
| `isLoading && devices == null` | centred mint `CircularProgressIndicator` filling the space |
| `error != null && devices == null` | error state |
| `devices` null or empty | empty state |
| otherwise | list of device rows, spacing `md` |

Loading, error and empty are deliberately separate: a slow network must never look like
owning zero devices.

**Add button**: 36×36, radius `md`, background `mint`, `Icons.add` 20 in `ink`.
Accessible label / tooltip `Add device`.

**Device row** (tap → `onDeviceTap(device)`): full width; radius `lg`; background
`inkPanel`; 1px `borderDark` border; padding `lg`. Row:
- 44×44 box, radius `md`, background `inkPanelHigh`, centred icon 20 in `mint`:
  `BatteryIcon` for inverter, `WaterDropIcon` for pump (`DeviceKind.from(device.kind)`).
- gap `md`
- expanded column: `deviceUid` (`subtitle`, `onInk`); 2px gap; caption (`onInkMuted`):
  `addressLine`, or if null `Serial {serialNo ?? imei}`.
- `Icons.arrow_forward` 18 `onInkMuted`.

**Empty state** (centred): `No devices yet` (`title`, `onInk`); gap `xs`;
`Scan the QR code on your device to add it.` (`body`, `onInkMuted`); gap `lg`;
`ClaroPrimaryButton('Add a device')` → `onAddDevice`.

**Error state** (centred): `Couldn't load your devices` (`title`, `onInk`); gap `xs`;
the error message (`body`, `onInkMuted`); gap `lg`; `ClaroPrimaryButton('Try again')` → `onRetry`.

---

## 4. `lib/ui/devices/device_detail_screen.dart` (from `DeviceDetailScreen.kt`)

`DeviceDetailScreen({required MyDevice device, required ClaroPulseApi api, required VoidCallback onBack})`.
Replaces the device-detail `OverlayPlaceholder` in `HomeScreen`
(`DeviceDetailRoute(:final device) => DeviceDetailScreen(device: device, api: widget.services.api, onBack: ...)`).

It fetches its own status (not Home's cache): the farmer may open a device Home isn't showing.

**State**: `status`, `statusError`, `range` (default day), `series` (default runHours),
`activity`, `activityError`, `isLoadingActivity`.
- Load status once on open.
- **Pump only**: load activity on open and every time `range` changes. Keep the previous
  `activity` on screen while a new range loads (spinner only when `activity == null`).
- **Inverter**: never request activity (the API has no inverter history).

**Layout**: `Scaffold`, background `ink`, `SafeArea`.
- Header row, padding `lg`: a 36×36 circle (`inkPanel`) with `Icons.arrow_back` 20 `onInk`
  (tooltip `Back`, tap → `onBack`); gap `md`; `deviceUid` in `title`, `onInk`.
- Scrollable body, horizontal padding `xl`:
  1. if status loaded: `DeviceHeroCard(kind, isRunning: isDeviceRunning(status),
     callouts: heroCalloutsFor(...), todaySummary: heroTodaySummaryFor(...),
     comingSoon: kind == inverter)`; else if no error: a 200-high box with a centred
     mint spinner; else nothing.
  2. gap `xl`
  3. if `statusError != null && status == null`: centred column, `Couldn't load this
     device's data` (`body`, `onInkMuted`), gap `md`, `ClaroPrimaryButton('Try again')`
     → reload status. Else if status loaded: `DeviceStatusBanners(status)`.
  4. gap `xxl`
  5. **Pump**: history section. **Inverter**: note box (radius `lg`, `inkPanel`,
     padding `xl`) with `Historical charts will appear here once this device starts
     reporting extended telemetry.` (`body`, `onInkMuted`).
  6. gap `xl`

**History section**:
- `History` (`title`, `onInk`); gap `md`
- Row of series pills, spacing `sm`: `Run Hours`, `Energy`, `Water`
- gap `sm`
- Row of range pills, spacing `sm`: `Day`, `Week`, `Month`
- gap `lg`
- Box: radius `lg`, `inkPanel`, padding `lg`, containing:
  - loading and `activity == null`: 196-high box, centred mint spinner
  - error and `activity == null`: centred `Couldn't load history` (`body`, `onInkMuted`),
    gap `md`, `ClaroPrimaryButton('Try again')` → reload current range
  - activity loaded: `ClaroLineChart(points: activityChartValues(activity.points, series),
    xLabels: activityChartLabels(activity.points, range))`

**Pill**: radius `pill`; background `mint` if selected, else `inkPanel`; padding
horizontal `md`, vertical `sm`; text `ClaroType.label`, colour `ink` if selected else
`onInkMuted`. Tap selects it.

Android back is already handled by `HomeScreen`'s `PopScope`.

---

## 5. Wiring and clean-up

- `HomeScreen`: use `DevicesTab` for the Devices tab and `DeviceDetailScreen` for
  `DeviceDetailRoute`.
- Remove `DevicesTabPlaceholder` from `placeholder_screens.dart` (keep the others; later
  phases replace them).
- Don't change the mock's device list (tests rely on exactly one pump and one inverter).
  For fault, protection, stopped and offline states, use a test-only subclass of
  `MockClaroPulseApi`.
- Fix the two analyzer infos: remove the unused `dart:ui` import in `claro_type.dart`;
  use the `?current` null-aware element in `auth_screen.dart` if your analyzer suggests it.

## 6. Tests

- `device_metrics`: pump callout formatting and rounding; nulls → `noData`; inverter all
  `noData` and empty today summary; chart values keep nulls; label counts (24 → 3, 1 → 1,
  0 → 0) and formats per range.
- `device_status_banners`: each run status label; fault text shown; all three protection
  texts; connection labels for online / offline / never reported, with and without
  `lastReportedAt`.
- `devices_tab`: loading, error with retry, empty with add, rows (address and the `Serial …`
  fallback), row tap, add button (find by tooltip `Add device`).
- `device_detail_screen`: pump shows hero, `Pump running`, `History`, pills; tapping `Week`
  requests the week range; inverter shows the note and never calls activity; status
  error shows `Try again` and retry works.
- Update `test/ui/home_screen_test.dart`: the detail test now expects the real detail
  screen; the add-device test must use the `Add device` tooltip on the Devices tab,
  since `Add a device` only appears in the empty state.

Spinners animate forever, so use `pump(Duration)` rather than `pumpAndSettle` while one is
visible.
