/// The device types this app renders, ported from the Kotlin `DeviceKind`.
///
/// The server also knows `BATTERY`, `ENERGY_METER` and `SMART_STARTER`, but the
/// farmer API models none of them yet, so every other or unknown code folds into
/// [pump], the app's original device. [inverter] is real but has no telemetry
/// fields yet, so the hero card shows it as "coming soon" rather than inventing numbers.
enum DeviceKind {
  pump,
  inverter;

  static DeviceKind from(String? rawCode) => rawCode == 'INVERTER' ? inverter : pump;
}

/// Shown in place of a value the device has not reported. A plain dash reads as
/// "nothing here", never as a real zero.
const String noData = '—';
