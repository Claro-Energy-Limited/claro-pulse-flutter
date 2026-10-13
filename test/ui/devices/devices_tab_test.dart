import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:claropulse/app/theme/claro_theme.dart';
import 'package:claropulse/core/api/models/device_models.dart';
import 'package:claropulse/ui/devices/devices_tab.dart';

const _pump = MyDevice(
  deviceId: 'p1',
  deviceUid: 'CP-PUMP-1',
  imei: '111',
  serialNo: 'SER-1',
  siteId: 's1',
  addressLine: 'Survey No. 1, Chevella',
  assignedAt: '2026-01-01T00:00:00Z',
  kind: 'PUMP',
);

const _noAddress = MyDevice(
  deviceId: 'i1',
  deviceUid: 'CP-INV-1',
  imei: '222',
  serialNo: null,
  siteId: 's2',
  addressLine: null,
  assignedAt: '2026-01-01T00:00:00Z',
  kind: 'INVERTER',
);

void main() {
  var retries = 0;
  var adds = 0;
  MyDevice? tapped;

  setUp(() {
    retries = 0;
    adds = 0;
    tapped = null;
  });

  Future<void> pumpTab(WidgetTester tester, {List<MyDevice>? devices, bool isLoading = false, String? error}) =>
      tester.pumpWidget(MaterialApp(
        theme: ClaroTheme.dark,
        home: Scaffold(
          body: DevicesTab(
            devices: devices,
            isLoading: isLoading,
            error: error,
            onRetry: () => retries++,
            onDeviceTap: (d) => tapped = d,
            onAddDevice: () => adds++,
          ),
        ),
      ));

  testWidgets('loading shows a spinner, not the empty state', (tester) async {
    await pumpTab(tester, isLoading: true);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('No devices yet'), findsNothing);
    expect(find.text('Your devices'), findsOneWidget);
  });

  testWidgets('error shows the message and retry', (tester) async {
    await pumpTab(tester, error: 'Server unavailable');
    expect(find.text("Couldn't load your devices"), findsOneWidget);
    expect(find.text('Server unavailable'), findsOneWidget);

    await tester.tap(find.text('Try again'));
    expect(retries, 1);
  });

  testWidgets('empty state offers to add a device', (tester) async {
    await pumpTab(tester, devices: const []);
    expect(find.text('No devices yet'), findsOneWidget);
    expect(find.text('Scan the QR code on your device to add it.'), findsOneWidget);

    await tester.tap(find.text('Add a device'));
    expect(adds, 1);
  });

  testWidgets('rows show the address, or the serial when there is none', (tester) async {
    await pumpTab(tester, devices: const [_pump, _noAddress]);
    expect(find.text('CP-PUMP-1'), findsOneWidget);
    expect(find.text('Survey No. 1, Chevella'), findsOneWidget);
    expect(find.text('CP-INV-1'), findsOneWidget);
    expect(find.text('Serial 222'), findsOneWidget, reason: 'no serial number, so the IMEI is shown');
  });

  testWidgets('tapping a row opens that device', (tester) async {
    await pumpTab(tester, devices: const [_pump, _noAddress]);
    await tester.tap(find.text('CP-INV-1'));
    expect(tapped?.deviceId, 'i1');
  });

  testWidgets('the add button in the header adds a device', (tester) async {
    await pumpTab(tester, devices: const [_pump]);
    await tester.tap(find.byTooltip('Add device'));
    expect(adds, 1);
  });

  testWidgets('a failed refresh keeps showing the devices already loaded', (tester) async {
    await pumpTab(tester, devices: const [_pump], error: 'Server unavailable');
    expect(find.text('CP-PUMP-1'), findsOneWidget);
    expect(find.text("Couldn't load your devices"), findsNothing);
  });
}
