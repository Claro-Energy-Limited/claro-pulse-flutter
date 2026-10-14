import 'package:flutter_test/flutter_test.dart';

import 'package:claropulse/core/api/api_exception.dart';
import 'package:claropulse/core/api/mock_claro_pulse_api.dart';
import 'package:claropulse/core/api/models/device_models.dart';
import 'package:claropulse/core/api/models/pump_models.dart';

void main() {
  late MockClaroPulseApi api;
  setUp(() => api = MockClaroPulseApi(latency: Duration.zero, confirmDelay: Duration.zero));

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
    expect(pump.live.flowRateLpm, isNotNull);
    final inverter = await api.getDeviceStatus(MockClaroPulseApi.inverterId);
    expect(inverter.live.solarPowerKw, isNull);
    await expectLater(api.getDeviceStatus('nope'), throwsA(isA<ApiException>()));
  });

  test('stop then start: status changes only after the pump confirms', () async {
    final slow = MockClaroPulseApi(latency: Duration.zero, confirmDelay: const Duration(hours: 1));
    await slow.sendPumpCommand(MockClaroPulseApi.pumpId, PumpCommand.stop);
    expect((await slow.getDeviceStatus(MockClaroPulseApi.pumpId)).runStatus, 'RUNNING',
        reason: 'not confirmed yet');

    await api.sendPumpCommand(MockClaroPulseApi.pumpId, PumpCommand.stop);
    final stopped = await api.getDeviceStatus(MockClaroPulseApi.pumpId);
    expect(stopped.runStatus, 'STOPPED');
    expect(stopped.live.flowRateLpm, 0);

    await api.sendPumpCommand(MockClaroPulseApi.pumpId, PumpCommand.start);
    expect((await api.getDeviceStatus(MockClaroPulseApi.pumpId)).runStatus, 'RUNNING');
  });

  test('the inverter cannot be controlled', () async {
    await expectLater(
      api.sendPumpCommand(MockClaroPulseApi.inverterId, PumpCommand.start),
      throwsA(isA<ApiException>()),
    );
  });

  test('pump details exist for both devices', () async {
    expect((await api.getPumpDetails(MockClaroPulseApi.pumpId)).capacity, '5 HP');
    expect((await api.getPumpDetails(MockClaroPulseApi.inverterId)).capacity, '3 kW');
  });

  test('complaints: seeded, then a new one is open and listed first', () async {
    expect(await api.listComplaints(), hasLength(2));
    await expectLater(
      api.createComplaint(deviceId: MockClaroPulseApi.pumpId, category: ComplaintCategory.other, description: 'x'),
      throwsA(isA<ApiException>()),
    );
    final created = await api.createComplaint(
      deviceId: MockClaroPulseApi.pumpId,
      category: ComplaintCategory.lowWaterFlow,
      description: 'Very little water today',
    );
    expect(created.status, ComplaintStatus.open);
    expect((await api.listComplaints()).first.ticketNo, created.ticketNo);
  });

  test('notifications include unread alerts', () async {
    final alerts = await api.listNotifications();
    expect(alerts.where((a) => !a.read), hasLength(2));
  });

  test('activity ranges have the right number of points', () async {
    expect((await api.getDeviceActivity(MockClaroPulseApi.pumpId, ActivityRange.day)).points, hasLength(24));
    expect((await api.getDeviceActivity(MockClaroPulseApi.pumpId, ActivityRange.week)).points, hasLength(7));
    expect((await api.getDeviceActivity(MockClaroPulseApi.pumpId, ActivityRange.month)).points, hasLength(30));
  });

  test('device claims are submitted as pending and listed', () async {
    final claim = await api.submitDeviceClaim(deviceIdentifier: ' CP-PUMP-0999 ', proofReference: 'QR scan');
    expect(claim.status, 'PENDING');
    expect((await api.listMyDeviceClaims()).items.first.id, claim.id);
  });
}
