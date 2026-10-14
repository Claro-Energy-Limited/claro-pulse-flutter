import 'dart:math';

import 'package:flutter/foundation.dart';

import 'api_exception.dart';
import 'claro_pulse_api.dart';
import 'models/auth_models.dart';
import 'models/device_models.dart';
import 'models/pump_models.dart';

/// Built-in fake backend, so every screen can be used and tested without a server.
///
/// Behaves like the real API: same data shapes, same error envelope messages,
/// a short delay like a mobile network. Sign in with any 10-digit number and
/// the code [otpCode]. One running pump and one inverter are attached.
///
/// Start/stop is simulated like a real pump: the command is accepted at once,
/// but the pump's reported status only changes after [confirmDelay], the way a
/// real controller reports back on its next update.
class MockClaroPulseApi implements ClaroPulseApi {
  MockClaroPulseApi({
    this.latency = const Duration(milliseconds: 700),
    this.confirmDelay = const Duration(seconds: 2),
    Random? random,
  }) : _random = random ?? Random();

  /// The one OTP code the mock accepts.
  static const otpCode = '123456';

  static const pumpId = 'mock-pump-1';
  static const inverterId = 'mock-inverter-1';

  final Duration latency;
  final Duration confirmDelay;
  final Random _random;
  final List<DeviceClaim> _claims = [];

  // ── Simulated pump state ──────────────────────────────────────────────────
  bool _pumpRunning = true;
  bool? _pendingRunning;
  DateTime? _pendingSince;
  DateTime _lastStateChange = DateTime.now().toUtc().subtract(const Duration(hours: 3, minutes: 12));

  late final List<Complaint> _complaints = _seedComplaints();
  late final List<AppNotification> _notifications = _seedNotifications();

  Future<void> _network() => latency == Duration.zero ? Future.value() : Future.delayed(latency);

  /// Applies a pending start/stop once the "pump" has had time to react.
  void _settlePending() {
    final pending = _pendingRunning;
    final since = _pendingSince;
    if (pending == null || since == null) return;
    if (DateTime.now().toUtc().difference(since) >= confirmDelay) {
      _pumpRunning = pending;
      _lastStateChange = DateTime.now().toUtc();
      _pendingRunning = null;
      _pendingSince = null;
    }
  }

  // ── Sign-in ──────────────────────────────────────────────────────────────

  @override
  Future<void> requestOtp(String phone) async {
    await _network();
    if (!RegExp(r'^\d{10}$').hasMatch(phone)) {
      throw const ApiException(code: 'VALIDATION_ERROR', message: 'Enter a valid 10-digit mobile number.');
    }
    debugPrint('MOCK API: code for +91 $phone is $otpCode');
  }

  @override
  Future<OtpVerifyResponse> verifyOtp(String phone, String code) async {
    await _network();
    if (code != otpCode) {
      throw const ApiException(code: 'OTP_INVALID', message: 'The code is invalid or has expired.');
    }
    return const OtpVerifyResponse(accessToken: 'mock-access-token', refreshToken: 'mock-refresh-token');
  }

  // ── Devices ──────────────────────────────────────────────────────────────

  @override
  Future<List<MyDevice>> listMyDevices() async {
    await _network();
    return const [
      MyDevice(
        deviceId: pumpId,
        deviceUid: 'CP-PUMP-0142',
        imei: '861236078001482',
        serialNo: 'SP5HP-22-0142',
        siteId: 'mock-site-1',
        addressLine: 'Survey No. 214, Chevella, Rangareddy',
        assignedAt: '2026-03-14T09:30:00Z',
        kind: 'PUMP',
      ),
      MyDevice(
        deviceId: inverterId,
        deviceUid: 'CP-INV-0087',
        imei: '861236078009931',
        serialNo: 'INV3KW-23-0087',
        siteId: 'mock-site-2',
        addressLine: 'H.No. 4-12, Shamshabad',
        assignedAt: '2026-06-02T11:00:00Z',
        kind: 'INVERTER',
      ),
    ];
  }

  @override
  Future<DeviceStatus> getDeviceStatus(String deviceId) async {
    await _network();
    _settlePending();
    final now = DateTime.now().toUtc();

    if (deviceId == inverterId) {
      // Inverters have no telemetry fields yet: an honest "nothing to show".
      return DeviceStatus(
        deviceId: inverterId,
        deviceUid: 'CP-INV-0087',
        runStatus: 'UNKNOWN',
        connectionStatus: 'ONLINE',
        lastReportedAt: now.subtract(const Duration(minutes: 3)).toIso8601String(),
        today: const TodayTotals(),
        live: const LiveReadings(),
        faultText: null,
        protections: const Protections(dryRun: false, waterLevelLow: false),
      );
    }
    if (deviceId != pumpId) {
      throw const ApiException(code: 'NOT_FOUND', message: 'Device not found.');
    }

    double drift(double base, double spread) => base + (_random.nextDouble() * 2 - 1) * spread;
    double round1(double v) => (v * 10).roundToDouble() / 10;

    // Today's totals keep growing while the pump runs.
    final runningMinutes = _pumpRunning ? now.difference(_lastStateChange).inMinutes : 0;
    final extraHours = runningMinutes / 60;

    return DeviceStatus(
      deviceId: pumpId,
      deviceUid: 'CP-PUMP-0142',
      runStatus: _pumpRunning ? 'RUNNING' : 'STOPPED',
      connectionStatus: 'ONLINE',
      lastReportedAt: now.subtract(const Duration(minutes: 1)).toIso8601String(),
      today: TodayTotals(
        runHours: round1(1.0 + extraHours),
        energyKwh: round1(3.2 + extraHours * 3.1),
        waterLiters: (17000 + extraHours * 17000).roundToDouble(),
      ),
      live: LiveReadings(
        solarPowerKw: round1(drift(5.2, 0.3)),
        flowRateLpm: _pumpRunning ? round1(drift(288, 12)) : 0,
        motorSpeedRpm: _pumpRunning ? drift(2880, 30).roundToDouble() : 0,
        workingHeadM: 70,
      ),
      faultText: null,
      protections: const Protections(dryRun: false, waterLevelLow: false),
    );
  }

  @override
  Future<DeviceActivity> getDeviceActivity(String deviceId, ActivityRange range) async {
    await _network();
    final now = DateTime.now().toUtc();
    final points = <ActivityPoint>[];

    switch (range) {
      case ActivityRange.day:
        final start = DateTime.utc(now.year, now.month, now.day);
        for (var h = 0; h < 24; h++) {
          final daylight = h >= 6 && h <= 18;
          // A missed hour at 13:00 shows how a reporting gap looks on the chart.
          final missing = h == 13 || h > now.hour;
          final sun = daylight ? sin((h - 6) / 12 * pi) : 0.0;
          points.add(ActivityPoint(
            bucketStart: start.add(Duration(hours: h)).toIso8601String(),
            runHours: missing ? null : (daylight ? 1.0 : 0.0),
            energyKwh: missing ? null : double.parse((sun * 3.2).toStringAsFixed(2)),
            waterLiters: missing ? null : (sun * 17000).roundToDouble(),
          ));
        }
      case ActivityRange.week:
      case ActivityRange.month:
        final days = range == ActivityRange.week ? 7 : 30;
        for (var d = days - 1; d >= 0; d--) {
          final day = DateTime.utc(now.year, now.month, now.day).subtract(Duration(days: d));
          final cloudy = 0.6 + _random.nextDouble() * 0.4;
          points.add(ActivityPoint(
            bucketStart: day.toIso8601String(),
            runHours: double.parse((7.5 * cloudy).toStringAsFixed(1)),
            energyKwh: double.parse((24 * cloudy).toStringAsFixed(1)),
            waterLiters: (90000 * cloudy).roundToDouble(),
          ));
        }
    }
    return DeviceActivity(deviceId: deviceId, range: range.queryValue, points: points);
  }

  // ── Adding a device ──────────────────────────────────────────────────────

  @override
  Future<DeviceClaim> submitDeviceClaim({
    required String deviceIdentifier,
    required String proofReference,
  }) async {
    await _network();
    if (deviceIdentifier.trim().isEmpty) {
      throw const ApiException(code: 'VALIDATION_ERROR', message: 'Enter the device ID.');
    }
    final claim = DeviceClaim(
      id: 'mock-claim-${_claims.length + 1}',
      deviceIdentifier: deviceIdentifier.trim(),
      deviceId: null,
      customerId: 'mock-customer-1',
      claimedVia: 'APP',
      verificationMethod: 'ADMIN_REVIEW',
      proofReference: proofReference,
      status: 'PENDING',
      reviewedBy: null,
      reviewedAt: null,
      rejectionReason: null,
      createdAt: DateTime.now().toUtc().toIso8601String(),
    );
    _claims.insert(0, claim);
    return claim;
  }

  @override
  Future<DeviceClaimsPage> listMyDeviceClaims() async {
    await _network();
    return DeviceClaimsPage(items: List.unmodifiable(_claims), page: 1, pageSize: 20, total: _claims.length);
  }

  // ── Pump details ─────────────────────────────────────────────────────────

  @override
  Future<PumpDetails> getPumpDetails(String deviceId) async {
    await _network();
    switch (deviceId) {
      case pumpId:
        return const PumpDetails(
          deviceId: pumpId,
          model: 'Claro SP-5 Solar Surface Pump',
          capacity: '5 HP',
          imei: '861236078001482',
          serialNo: 'SP5HP-22-0142',
          installedOn: '2026-03-14',
          siteAddress: 'Survey No. 214, Chevella, Rangareddy',
          installedBy: 'Sri Sai Solar Installers',
          warrantyUntil: '2031-03-14',
          controller: 'STACON VFD 5.5 kW',
          panels: '12 × 335 W panels',
        );
      case inverterId:
        return const PumpDetails(
          deviceId: inverterId,
          model: 'Claro Hybrid Solar Inverter',
          capacity: '3 kW',
          imei: '861236078009931',
          serialNo: 'INV3KW-23-0087',
          installedOn: '2026-06-02',
          siteAddress: 'H.No. 4-12, Shamshabad',
          installedBy: 'Sri Sai Solar Installers',
          warrantyUntil: '2031-06-02',
          controller: 'Built-in MPPT charger',
          panels: '8 × 400 W panels',
        );
      default:
        throw const ApiException(code: 'NOT_FOUND', message: 'Device not found.');
    }
  }

  // ── Pump control ─────────────────────────────────────────────────────────

  @override
  Future<void> sendPumpCommand(String deviceId, PumpCommand command) async {
    await _network();
    if (deviceId != pumpId) {
      throw const ApiException(code: 'NOT_SUPPORTED', message: "This device can't be controlled from the app.");
    }
    _settlePending();
    _pendingRunning = command == PumpCommand.start;
    _pendingSince = DateTime.now().toUtc();
    debugPrint('MOCK API: ${command.name} command accepted for $deviceId');
  }

  // ── Complaints ───────────────────────────────────────────────────────────

  List<Complaint> _seedComplaints() {
    final now = DateTime.now().toUtc();
    String ago(Duration d) => now.subtract(d).toIso8601String();
    return [
      Complaint(
        id: 'mock-complaint-2',
        ticketNo: 'CP-1038',
        deviceId: pumpId,
        category: ComplaintCategory.solarPanel,
        description: 'Two panels look cracked after the hailstorm.',
        status: ComplaintStatus.inProgress,
        createdAt: ago(const Duration(days: 2)),
        updatedAt: ago(const Duration(hours: 5)),
        latestUpdate: 'Technician visit scheduled for tomorrow morning.',
      ),
      Complaint(
        id: 'mock-complaint-1',
        ticketNo: 'CP-1031',
        deviceId: pumpId,
        category: ComplaintCategory.lowWaterFlow,
        description: 'Water flow is much lower than usual since Monday.',
        status: ComplaintStatus.resolved,
        createdAt: ago(const Duration(days: 12)),
        updatedAt: ago(const Duration(days: 10)),
        latestUpdate: 'Technician cleaned the foot valve. Flow is back to normal.',
      ),
    ];
  }

  @override
  Future<List<Complaint>> listComplaints() async {
    await _network();
    return List.unmodifiable(_complaints);
  }

  @override
  Future<Complaint> createComplaint({
    required String deviceId,
    required ComplaintCategory category,
    required String description,
  }) async {
    await _network();
    final text = description.trim();
    if (text.length < 5) {
      throw const ApiException(code: 'VALIDATION_ERROR', message: 'Please describe the problem in a few words.');
    }
    final now = DateTime.now().toUtc().toIso8601String();
    final complaint = Complaint(
      id: 'mock-complaint-${_complaints.length + 1}',
      ticketNo: 'CP-${1042 + _complaints.length}',
      deviceId: deviceId,
      category: category,
      description: text,
      status: ComplaintStatus.open,
      createdAt: now,
      updatedAt: now,
    );
    _complaints.insert(0, complaint);
    return complaint;
  }

  // ── Notifications ────────────────────────────────────────────────────────

  List<AppNotification> _seedNotifications() {
    final now = DateTime.now().toUtc();
    String ago(Duration d) => now.subtract(d).toIso8601String();
    return [
      AppNotification(
        id: 'n4',
        kind: NotificationKind.info,
        title: 'Complaint CP-1038 updated',
        body: 'Technician visit scheduled for tomorrow morning.',
        createdAt: ago(const Duration(hours: 5)),
      ),
      AppNotification(
        id: 'n3',
        kind: NotificationKind.fault,
        title: 'Pump paused: low water',
        body: 'Your pump stopped yesterday at 2:10 PM because the well ran low. It restarted on its own at 3:40 PM.',
        createdAt: ago(const Duration(days: 1)),
      ),
      AppNotification(
        id: 'n2',
        kind: NotificationKind.success,
        title: 'Your best day this week',
        body: 'Your pump moved 92,000 litres of water yesterday.',
        createdAt: ago(const Duration(days: 1, hours: 2)),
        read: true,
      ),
      AppNotification(
        id: 'n1',
        kind: NotificationKind.offline,
        title: 'Device back online',
        body: 'CP-PUMP-0142 was offline for 40 minutes and is reporting again.',
        createdAt: ago(const Duration(days: 5)),
        read: true,
      ),
    ];
  }

  @override
  Future<List<AppNotification>> listNotifications() async {
    await _network();
    return List.unmodifiable(_notifications);
  }
}
