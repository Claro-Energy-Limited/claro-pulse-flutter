import 'package:claropulse/core/api/models/device_models.dart';

/// Builds a [DeviceStatus] for tests; every field defaults to a healthy,
/// running, online pump with no readings.
DeviceStatus testStatus({
  String runStatus = 'RUNNING',
  String connectionStatus = 'ONLINE',
  String? lastReportedAt,
  TodayTotals today = const TodayTotals(),
  LiveReadings live = const LiveReadings(),
  String? faultText,
  bool dryRun = false,
  bool waterLevelLow = false,
}) =>
    DeviceStatus(
      deviceId: 'd1',
      deviceUid: 'CP-TEST-1',
      runStatus: runStatus,
      connectionStatus: connectionStatus,
      lastReportedAt: lastReportedAt,
      today: today,
      live: live,
      faultText: faultText,
      protections: Protections(dryRun: dryRun, waterLevelLow: waterLevelLow),
    );
