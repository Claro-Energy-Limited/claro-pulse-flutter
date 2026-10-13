import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:claropulse/app/theme/claro_theme.dart';
import 'package:claropulse/core/api/models/device_models.dart';
import 'package:claropulse/ui/devices/device_status_banners.dart';

import 'device_test_data.dart';

Future<void> _pump(WidgetTester tester, DeviceStatus status) => tester.pumpWidget(MaterialApp(
      theme: ClaroTheme.dark,
      home: Scaffold(body: SingleChildScrollView(child: DeviceStatusBanners(status: status))),
    ));

void main() {
  test('isDeviceRunning is true only for RUNNING', () {
    expect(isDeviceRunning(testStatus(runStatus: 'RUNNING')), isTrue);
    expect(isDeviceRunning(testStatus(runStatus: 'STOPPED')), isFalse);
    expect(isDeviceRunning(null), isFalse);
  });

  testWidgets('run status labels', (tester) async {
    for (final (status, label) in [
      ('RUNNING', 'Pump running'),
      ('STOPPED', 'Pump stopped'),
      ('UNKNOWN', 'Status unknown'),
      ('SOMETHING_NEW', 'Status unknown'),
    ]) {
      await _pump(tester, testStatus(runStatus: status));
      expect(find.text(label), findsOneWidget, reason: status);
    }
  });

  testWidgets('fault text is shown only when present', (tester) async {
    await _pump(tester, testStatus());
    expect(find.byIcon(Icons.warning), findsNothing);

    await _pump(tester, testStatus(faultText: 'Overcurrent trip'));
    expect(find.text('Overcurrent trip'), findsOneWidget);
    expect(find.byIcon(Icons.warning), findsOneWidget);
  });

  testWidgets('all three protection texts', (tester) async {
    await _pump(tester, testStatus(dryRun: true, waterLevelLow: true));
    expect(find.text('Dry-run and low water level protection active'), findsOneWidget);

    await _pump(tester, testStatus(dryRun: true));
    expect(find.text('Dry-run protection active — pump paused to avoid damage'), findsOneWidget);

    await _pump(tester, testStatus(waterLevelLow: true));
    expect(find.text('Low water level protection active'), findsOneWidget);
  });

  test('connection labels', () {
    final now = DateTime.utc(2026, 9, 10, 12);
    final twoMinAgo = now.subtract(const Duration(minutes: 2)).toIso8601String();

    expect(connectionLabel(testStatus(lastReportedAt: twoMinAgo), now: now), 'Online — updated 2 min ago');
    expect(connectionLabel(testStatus(), now: now), 'Online');
    expect(
      connectionLabel(testStatus(connectionStatus: 'OFFLINE', lastReportedAt: twoMinAgo), now: now),
      'Offline — last seen 2 min ago',
    );
    expect(connectionLabel(testStatus(connectionStatus: 'OFFLINE'), now: now), 'Offline');
    expect(
      connectionLabel(testStatus(connectionStatus: 'NEVER_REPORTED', lastReportedAt: twoMinAgo), now: now),
      'Never reported in yet',
    );
  });

  testWidgets('freshness stamp shows the connection label', (tester) async {
    await _pump(tester, testStatus(connectionStatus: 'NEVER_REPORTED'));
    expect(find.text('Never reported in yet'), findsOneWidget);
  });
}
