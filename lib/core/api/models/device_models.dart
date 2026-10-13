// Device data shapes, ported 1:1 from the Kotlin `DeviceDtos.kt`, which mirrors the
// RMS farmer-plane responses. Field names match the JSON exactly.

double? _toDouble(Object? value) => value is num ? value.toDouble() : null;

/// One row of `GET /app/v1/me/devices`.
///
/// [kind] is the equipment type code (`PUMP`, `INVERTER`, `BATTERY`, `ENERGY_METER`,
/// `SMART_STARTER`). Nullable: a legacy device predating that catalogue has none.
class MyDevice {
  const MyDevice({
    required this.deviceId,
    required this.deviceUid,
    required this.imei,
    required this.serialNo,
    required this.siteId,
    required this.addressLine,
    required this.assignedAt,
    required this.kind,
  });

  final String deviceId;
  final String deviceUid;
  final String imei;
  final String? serialNo;
  final String siteId;
  final String? addressLine;
  final String assignedAt;
  final String? kind;

  factory MyDevice.fromJson(Map<String, dynamic> json) => MyDevice(
        deviceId: json['deviceId'] as String,
        deviceUid: json['deviceUid'] as String,
        imei: json['imei'] as String,
        serialNo: json['serialNo'] as String?,
        siteId: json['siteId'] as String,
        addressLine: json['addressLine'] as String?,
        assignedAt: json['assignedAt'] as String,
        kind: json['kind'] as String?,
      );
}

/// A device claim as returned by `POST` and `GET /app/v1/me/device-claims`.
///
/// [status] is `PENDING`, `APPROVED` or `REJECTED`. A claim stays `PENDING` until
/// an admin approves it; submitting one does not attach the device immediately.
class DeviceClaim {
  const DeviceClaim({
    required this.id,
    required this.deviceIdentifier,
    required this.deviceId,
    required this.customerId,
    required this.claimedVia,
    required this.verificationMethod,
    required this.proofReference,
    required this.status,
    required this.reviewedBy,
    required this.reviewedAt,
    required this.rejectionReason,
    required this.createdAt,
  });

  final String id;
  final String deviceIdentifier;
  final String? deviceId;
  final String customerId;
  final String claimedVia;
  final String verificationMethod;
  final String proofReference;
  final String status;
  final String? reviewedBy;
  final String? reviewedAt;
  final String? rejectionReason;
  final String createdAt;

  factory DeviceClaim.fromJson(Map<String, dynamic> json) => DeviceClaim(
        id: json['id'] as String,
        deviceIdentifier: json['deviceIdentifier'] as String,
        deviceId: json['deviceId'] as String?,
        customerId: json['customerId'] as String,
        claimedVia: json['claimedVia'] as String,
        verificationMethod: json['verificationMethod'] as String,
        proofReference: json['proofReference'] as String,
        status: json['status'] as String,
        reviewedBy: json['reviewedBy'] as String?,
        reviewedAt: json['reviewedAt'] as String?,
        rejectionReason: json['rejectionReason'] as String?,
        createdAt: json['createdAt'] as String,
      );
}

class DeviceClaimsPage {
  const DeviceClaimsPage({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.total,
  });

  final List<DeviceClaim> items;
  final int page;
  final int pageSize;
  final int total;

  factory DeviceClaimsPage.fromJson(Map<String, dynamic> json) => DeviceClaimsPage(
        items: (json['items'] as List)
            .map((e) => DeviceClaim.fromJson(e as Map<String, dynamic>))
            .toList(),
        page: json['page'] as int,
        pageSize: json['pageSize'] as int,
        total: json['total'] as int,
      );
}

/// `GET /app/v1/me/devices/{id}/status`: the farmer's "is my pump running" view.
///
/// [runStatus] is `RUNNING`, `STOPPED` or `UNKNOWN`. [connectionStatus] is `ONLINE`,
/// `OFFLINE` or `NEVER_REPORTED`. Two separate questions (is it talking to us, and
/// is the pump physically running) that must never be collapsed into one.
class DeviceStatus {
  const DeviceStatus({
    required this.deviceId,
    required this.deviceUid,
    required this.runStatus,
    required this.connectionStatus,
    required this.lastReportedAt,
    required this.today,
    required this.live,
    required this.faultText,
    required this.protections,
  });

  final String deviceId;
  final String deviceUid;
  final String runStatus;
  final String connectionStatus;
  final String? lastReportedAt;
  final TodayTotals today;
  final LiveReadings live;
  final String? faultText;
  final Protections protections;

  factory DeviceStatus.fromJson(Map<String, dynamic> json) => DeviceStatus(
        deviceId: json['deviceId'] as String,
        deviceUid: json['deviceUid'] as String,
        runStatus: json['runStatus'] as String,
        connectionStatus: json['connectionStatus'] as String,
        lastReportedAt: json['lastReportedAt'] as String?,
        today: TodayTotals.fromJson(json['today'] as Map<String, dynamic>),
        live: LiveReadings.fromJson(json['live'] as Map<String, dynamic>),
        faultText: json['faultText'] as String?,
        protections: Protections.fromJson(json['protections'] as Map<String, dynamic>),
      );
}

/// Today's totals. `null` means "no reports", which is different from a real zero.
class TodayTotals {
  const TodayTotals({this.runHours, this.energyKwh, this.waterLiters});

  final double? runHours;
  final double? energyKwh;
  final double? waterLiters;

  factory TodayTotals.fromJson(Map<String, dynamic> json) => TodayTotals(
        runHours: _toDouble(json['runHours']),
        energyKwh: _toDouble(json['energyKwh']),
        waterLiters: _toDouble(json['waterLiters']),
      );
}

/// The latest reading's instantaneous values, not daily totals. Deliberately no
/// motor power: the server's motor power unit is unconfirmed, so it is not shown
/// to farmers as a kW figure.
class LiveReadings {
  const LiveReadings({this.solarPowerKw, this.flowRateLpm, this.motorSpeedRpm, this.workingHeadM});

  final double? solarPowerKw;
  final double? flowRateLpm;
  final double? motorSpeedRpm;
  final double? workingHeadM;

  factory LiveReadings.fromJson(Map<String, dynamic> json) => LiveReadings(
        solarPowerKw: _toDouble(json['solarPowerKw']),
        flowRateLpm: _toDouble(json['flowRateLpm']),
        motorSpeedRpm: _toDouble(json['motorSpeedRpm']),
        workingHeadM: _toDouble(json['workingHeadM']),
      );
}

class Protections {
  const Protections({required this.dryRun, required this.waterLevelLow});

  final bool dryRun;
  final bool waterLevelLow;

  factory Protections.fromJson(Map<String, dynamic> json) => Protections(
        dryRun: json['dryRun'] as bool,
        waterLevelLow: json['waterLevelLow'] as bool,
      );
}

/// The three windows `GET .../activity?range=` accepts. A missing or invalid value
/// is rejected by the server rather than defaulted, so the app always sends one.
enum ActivityRange {
  day('day'),
  week('week'),
  month('month');

  const ActivityRange(this.queryValue);
  final String queryValue;
}

/// One hourly bucket. A bucket with no reports is `null`, not `0`.
class ActivityPoint {
  const ActivityPoint({
    required this.bucketStart,
    this.runHours,
    this.energyKwh,
    this.waterLiters,
  });

  final String bucketStart;
  final double? runHours;
  final double? energyKwh;
  final double? waterLiters;

  factory ActivityPoint.fromJson(Map<String, dynamic> json) => ActivityPoint(
        bucketStart: json['bucketStart'] as String,
        runHours: _toDouble(json['runHours']),
        energyKwh: _toDouble(json['energyKwh']),
        waterLiters: _toDouble(json['waterLiters']),
      );
}

/// Chart data for the device detail screen.
class DeviceActivity {
  const DeviceActivity({required this.deviceId, required this.range, required this.points});

  final String deviceId;
  final String range;
  final List<ActivityPoint> points;

  factory DeviceActivity.fromJson(Map<String, dynamic> json) => DeviceActivity(
        deviceId: json['deviceId'] as String,
        range: json['range'] as String,
        points: (json['points'] as List)
            .map((e) => ActivityPoint.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
