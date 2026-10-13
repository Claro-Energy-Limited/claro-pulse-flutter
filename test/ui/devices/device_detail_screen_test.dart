import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:claropulse/app/theme/claro_theme.dart';
import 'package:claropulse/core/api/api_exception.dart';
import 'package:claropulse/core/api/mock_claro_pulse_api.dart';
import 'package:claropulse/core/api/models/device_models.dart';
import 'package:claropulse/ui/components/device_hero_card.dart';
import 'package:claropulse/ui/devices/device_detail_screen.dart';

/// The mock, recording activity requests and able to fail the status call.
class _SpyApi extends MockClaroPulseApi {
  _SpyApi({this.failStatus = false}) : super(latency: Duration.zero);

  bool failStatus;
  int statusCalls = 0;
  final List<ActivityRange> activityRanges = [];

  @override
  Future<DeviceStatus> getDeviceStatus(String deviceId) {
    statusCalls++;
    if (failStatus) throw const ApiException(message: 'Server unavailable');
    return super.getDeviceStatus(deviceId);
  }

  @override
  Future<DeviceActivity> getDeviceActivity(String deviceId, ActivityRange range) {
    activityRanges.add(range);
    return super.getDeviceActivity(deviceId, range);
  }
}

late MyDevice _pump;
late MyDevice _inverter;

/// The running pump's wires animate forever, so settle with fixed pumps.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 200));
  }
}

Future<void> _open(WidgetTester tester, _SpyApi api, MyDevice device, {VoidCallback? onBack}) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 2.5;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    theme: ClaroTheme.dark,
    home: DeviceDetailScreen(device: device, api: api, onBack: onBack ?? () {}),
  ));
  await _settle(tester);
}

void main() {
  setUpAll(() async {
    final devices = await MockClaroPulseApi(latency: Duration.zero).listMyDevices();
    _pump = devices.firstWhere((d) => d.kind == 'PUMP');
    _inverter = devices.firstWhere((d) => d.kind == 'INVERTER');
  });

  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  testWidgets('a pump shows the hero, its run status, and history with pills', (tester) async {
    final api = _SpyApi();
    await _open(tester, api, _pump);

    expect(find.text('CP-PUMP-0142'), findsOneWidget);
    expect(find.byType(DeviceHeroCard), findsOneWidget);
    expect(find.text('Pump running'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Month'), 200);
    expect(find.text('History'), findsOneWidget);
    for (final pill in ['Run Hours', 'Energy', 'Water', 'Day', 'Week', 'Month']) {
      expect(find.text(pill), findsOneWidget, reason: pill);
    }
    expect(api.activityRanges, [ActivityRange.day]);
  });

  testWidgets('tapping Week requests the week range', (tester) async {
    final api = _SpyApi();
    await _open(tester, api, _pump);
    await tester.scrollUntilVisible(find.text('Week'), 200);

    await tester.tap(find.text('Week'));
    await _settle(tester);
    expect(api.activityRanges, [ActivityRange.day, ActivityRange.week]);
  });

  testWidgets('an inverter shows the note and never asks for activity', (tester) async {
    final api = _SpyApi();
    await _open(tester, api, _inverter);

    expect(
      find.text('Historical charts will appear here once this device starts reporting extended telemetry.'),
      findsOneWidget,
    );
    expect(find.text('History'), findsNothing);
    expect(api.activityRanges, isEmpty);
  });

  testWidgets('a failed status shows Try again, and retry recovers', (tester) async {
    final api = _SpyApi(failStatus: true);
    await _open(tester, api, _inverter);

    expect(find.text("Couldn't load this device's data"), findsOneWidget);
    expect(find.byType(DeviceHeroCard), findsNothing);

    api.failStatus = false;
    await tester.tap(find.text('Try again'));
    await _settle(tester);
    expect(api.statusCalls, 2);
    expect(find.byType(DeviceHeroCard), findsOneWidget);
    expect(find.text('Status unknown'), findsOneWidget);
  });

  testWidgets('back calls onBack', (tester) async {
    var backs = 0;
    await _open(tester, _SpyApi(), _inverter, onBack: () => backs++);
    await tester.tap(find.byTooltip('Back'));
    expect(backs, 1);
  });
}
