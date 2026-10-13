import 'dart:math';

import 'package:flutter/foundation.dart';

import 'api_exception.dart';
import 'claro_pulse_api.dart';
import 'models/auth_models.dart';
import 'models/device_models.dart';

/// Built-in fake backend, so every screen can be used and tested without a server.
///
/// Behaves like the real API: same data shapes, same error envelope messages,
/// a short delay like a mobile network. Sign in with any 10-digit number and
/// the code [otpCode]. One running pump and one inverter are attached; pump
/// readings drift a little on every request so screens look alive.
class MockClaroPulseApi implements ClaroPulseApi {
  MockClaroPulseApi({this.latency = const Duration(milliseconds: 700), Random? random})
      : _random = random ?? Random();

  /// The one OTP code the mock accepts.
  static const otpCode = '123456';

  final Duration latency;
  final Random _random;
  final List<DeviceClaim> _claims = [];

  static const pumpId = 'mock-pump-1';
  static const inverterId = 'mock-inverter-1';

  Future<void> _network() => latency == Duration.zero ? Future.value() : Future.delayed(latency);

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

    return DeviceStatus(
      deviceId: pumpId,
      deviceUid: 'CP-PUMP-0142',
      runStatus: 'RUNNING',
      connectionStatus: 'ONLINE',
      lastReportedAt: now.subtract(const Duration(minutes: 1)).toIso8601String(),
      today: TodayTotals(runHours: 4.2, energyKwh: 12.6, waterLiters: 42000),
      live: LiveReadings(
        solarPowerKw: round1(drift(5.2, 0.3)),
        flowRateLpm: round1(drift(288, 12)),
        motorSpeedRpm: drift(2880, 30).roundToDouble(),
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
}
