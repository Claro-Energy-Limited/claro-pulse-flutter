import 'package:flutter/painting.dart';

import '../../app/theme/claro_colors.dart';
import '../../core/api/models/device_models.dart';
import '../../core/api/models/pump_models.dart';
import '../devices/device_kind.dart';

/// What the farmer should understand about a device at a glance. One place
/// decides it, so Home, the status chip and the control button never disagree.
enum PumpVisual {
  running('Running'),
  starting('Starting…'),
  stopping('Stopping…'),
  stopped('Stopped'),
  attention('Needs attention'),
  offline('Offline'),
  notReporting('Not reporting yet'),
  checking('Checking…'),
  unknown('Status unknown'),
  inverterSoon('Readings coming soon');

  const PumpVisual(this.label);
  final String label;

  Color get color => switch (this) {
        PumpVisual.running => ClaroColors.mint,
        PumpVisual.starting || PumpVisual.stopping => ClaroColors.warn,
        PumpVisual.attention => ClaroColors.fault,
        _ => ClaroColors.onInkMuted,
      };

  /// Only a pump that is actually running gets a moving indicator.
  bool get isLive => this == PumpVisual.running;
}

PumpVisual pumpVisualFor({
  required DeviceKind kind,
  required DeviceStatus? status,
  PumpCommand? pending,
}) {
  if (kind == DeviceKind.inverter) return PumpVisual.inverterSoon;
  if (pending == PumpCommand.start) return PumpVisual.starting;
  if (pending == PumpCommand.stop) return PumpVisual.stopping;
  if (status == null) return PumpVisual.checking;
  if (status.connectionStatus == 'NEVER_REPORTED') return PumpVisual.notReporting;
  if (status.connectionStatus != 'ONLINE') return PumpVisual.offline;
  if (needsAttention(status)) return PumpVisual.attention;
  return switch (status.runStatus) {
    'RUNNING' => PumpVisual.running,
    'STOPPED' => PumpVisual.stopped,
    _ => PumpVisual.unknown,
  };
}

bool needsAttention(DeviceStatus status) =>
    status.faultText != null || status.protections.dryRun || status.protections.waterLevelLow;

/// Why the pump can't be started right now, in plain words, or null if it can.
///
/// Safety first: never offer "Start" for a pump that is offline (the command
/// couldn't be confirmed), has a fault, or is protecting itself from running dry.
String? startBlockedReason(DeviceStatus? status) {
  if (status == null) return 'Waiting for the pump to report in.';
  if (status.connectionStatus != 'ONLINE') return "The pump is offline, so it can't be started from the app.";
  if (status.protections.dryRun) return 'Dry-run protection is on: there may not be enough water in the well.';
  if (status.protections.waterLevelLow) return 'The water level is low.';
  if (status.faultText != null) return 'The pump has reported a fault: ${status.faultText}';
  return null;
}
