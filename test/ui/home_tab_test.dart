import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:claropulse/app/theme/claro_theme.dart';
import 'package:claropulse/core/api/models/device_models.dart';
import 'package:claropulse/ui/components/device_hero_card.dart';
import 'package:claropulse/ui/home/home_tab.dart';

import 'devices/device_test_data.dart';

const _device = MyDevice(
  deviceId: 'p1',
  deviceUid: 'CP-PUMP-1',
  imei: '111',
  serialNo: 'SER-1',
  siteId: 's1',
  addressLine: null,
  assignedAt: '2026-01-01T00:00:00Z',
  kind: 'PUMP',
);

DeviceClaim _claim(String status) => DeviceClaim(
      id: 'c-$status',
      deviceIdentifier: 'CP-NEW-$status',
      deviceId: null,
      customerId: 'cust',
      claimedVia: 'APP',
      verificationMethod: 'ADMIN_REVIEW',
      proofReference: 'qr',
      status: status,
      reviewedBy: null,
      reviewedAt: null,
      rejectionReason: null,
      createdAt: '2026-01-01T00:00:00Z',
    );

/// Everything the tab's callbacks were called with.
class _Calls {
  int retryDevices = 0;
  int addDevice = 0;
  final List<int> settled = [];
  final List<String> retryStatus = [];
}

Future<_Calls> _pumpTab(
  WidgetTester tester, {
  List<MyDevice>? devices,
  String? devicesError,
  List<DeviceClaim>? claims,
  Map<String, DeviceStatus> statusById = const {},
  Map<String, String> statusErrorById = const {},
}) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 2.5;
  addTearDown(tester.view.reset);
  final calls = _Calls();
  await tester.pumpWidget(MaterialApp(
    theme: ClaroTheme.dark,
    home: Scaffold(
      body: SingleChildScrollView(
        child: HomeTab(
          devices: devices,
          devicesError: devicesError,
          claims: claims,
          statusById: statusById,
          statusErrorById: statusErrorById,
          onRetryDevices: () => calls.retryDevices++,
          onPageSettled: calls.settled.add,
          onRetryStatus: calls.retryStatus.add,
          onAddDevice: () => calls.addDevice++,
        ),
      ),
    ),
  ));
  // Spinners, the sun and running wires animate forever: pump, don't settle.
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  return calls;
}

void main() {
  testWidgets('1. loading: a spinner, nothing else', (tester) async {
    await _pumpTab(tester);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('No devices yet'), findsNothing);
  });

  testWidgets('2. error: message, and Try again retries the device list', (tester) async {
    final calls = await _pumpTab(tester, devicesError: 'Server unavailable');
    expect(find.text("Couldn't load your dashboard"), findsOneWidget);
    expect(find.text('Server unavailable'), findsOneWidget);

    await tester.tap(find.text('Try again'));
    expect(calls.retryDevices, 1);
  });

  testWidgets('3. pending claim: shown instead of the empty state', (tester) async {
    await _pumpTab(tester, devices: const [], claims: [_claim('REJECTED'), _claim('PENDING')]);
    expect(find.text('Pending review'), findsOneWidget);
    expect(
      find.text("Device CP-NEW-PENDING is waiting for your utility's team to approve it. "
          "You'll see its data here once that's done."),
      findsOneWidget,
    );
    expect(find.text('31°C'), findsOneWidget);
    expect(find.text('No devices yet'), findsNothing);
  });

  testWidgets('4. empty: weather and Add device', (tester) async {
    final calls = await _pumpTab(tester, devices: const [], claims: const []);
    expect(find.text('31°C'), findsOneWidget);
    expect(find.text('No devices yet'), findsOneWidget);
    expect(find.text('Scan the QR code on your device to add it to your account.'), findsOneWidget);

    await tester.tap(find.text('Add device'));
    expect(calls.addDevice, 1);
  });

  testWidgets('4. empty: a rejected claim alone is not pending', (tester) async {
    await _pumpTab(tester, devices: const [], claims: [_claim('REJECTED')]);
    expect(find.text('No devices yet'), findsOneWidget);
    expect(find.text('Pending review'), findsNothing);
  });

  testWidgets('5. pager: status loaded shows the hero card and banners', (tester) async {
    final calls = await _pumpTab(
      tester,
      devices: const [_device],
      statusById: {'p1': testStatus(runStatus: 'RUNNING')},
    );
    expect(find.text('CP-PUMP-1'), findsOneWidget);
    expect(find.byType(DeviceHeroCard), findsOneWidget);
    expect(find.text('Pump running'), findsOneWidget);
    expect(calls.settled, [0]);
  });

  testWidgets('5. pager: status not loaded yet shows a spinner', (tester) async {
    await _pumpTab(tester, devices: const [_device]);
    expect(find.text('CP-PUMP-1'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(DeviceHeroCard), findsNothing);
  });

  testWidgets('5. pager: status error retries that device', (tester) async {
    final calls = await _pumpTab(tester, devices: const [_device], statusErrorById: {'p1': 'Timed out'});
    expect(find.text("Couldn't load your dashboard"), findsOneWidget);
    expect(find.text('Timed out'), findsOneWidget);

    await tester.tap(find.text('Try again'));
    expect(calls.retryStatus, ['p1']);
    expect(calls.retryDevices, 0);
  });
}
