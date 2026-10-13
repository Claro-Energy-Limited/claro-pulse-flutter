import 'package:flutter_test/flutter_test.dart';

import 'package:claropulse/core/api/api_exception.dart';
import 'package:claropulse/core/api/mock_claro_pulse_api.dart';
import 'package:claropulse/core/api/models/device_models.dart';

void main() {
  final api = MockClaroPulseApi(latency: Duration.zero);

  test('OTP: rejects a bad number and a wrong code, accepts the mock code', () async {
    await expectLater(api.requestOtp('123'), throwsA(isA<ApiException>()));
    await api.requestOtp('9876543210');
    await expectLater(
      api.verifyOtp('9876543210', '000000'),
      throwsA(isA<ApiException>().having((e) => e.code, 'code', 'OTP_INVALID')),
    );
    final tokens = await api.verifyOtp('9876543210', MockClaroPulseApi.otpCode);
    expect(tokens.accessToken, isNotEmpty);
  });

  test('lists a pump and an inverter', () async {
    final devices = await api.listMyDevices();
    expect(devices.map((d) => d.kind), ['PUMP', 'INVERTER']);
  });

  test('pump status is running with live readings; inverter has none', () async {
    final pump = await api.getDeviceStatus(MockClaroPulseApi.pumpId);
    expect(pump.runStatus, 'RUNNING');
    expect(pump.connectionStatus, 'ONLINE');
    expect(pump.live.flowRateLpm, isNotNull);

    final inverter = await api.getDeviceStatus(MockClaroPulseApi.inverterId);
    expect(inverter.live.solarPowerKw, isNull);
    expect(inverter.today.waterLiters, isNull);

    await expectLater(api.getDeviceStatus('nope'), throwsA(isA<ApiException>()));
  });

  test('activity ranges have the right number of points', () async {
    final day = await api.getDeviceActivity(MockClaroPulseApi.pumpId, ActivityRange.day);
    final week = await api.getDeviceActivity(MockClaroPulseApi.pumpId, ActivityRange.week);
    final month = await api.getDeviceActivity(MockClaroPulseApi.pumpId, ActivityRange.month);
    expect(day.points, hasLength(24));
    expect(day.points[13].waterLiters, isNull, reason: 'deliberate reporting gap');
    expect(week.points, hasLength(7));
    expect(month.points, hasLength(30));
  });

  test('device claims are submitted as pending and listed', () async {
    final claim = await api.submitDeviceClaim(deviceIdentifier: ' CP-PUMP-0999 ', proofReference: 'QR scan');
    expect(claim.status, 'PENDING');
    expect(claim.deviceIdentifier, 'CP-PUMP-0999');
    final page = await api.listMyDeviceClaims();
    expect(page.items.first.id, claim.id);
  });
}
