import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:claropulse/app/theme/claro_theme.dart';
import 'package:claropulse/core/api/api_exception.dart';
import 'package:claropulse/core/api/claro_pulse_api.dart';
import 'package:claropulse/core/api/mock_claro_pulse_api.dart';
import 'package:claropulse/core/api/models/device_models.dart';
import 'package:claropulse/core/auth/session_expiry.dart';
import 'package:claropulse/core/auth/token_store.dart';
import 'package:claropulse/core/services.dart';
import 'package:claropulse/ui/home/home_screen.dart';

/// The mock, but with a device list that fails or is empty, to check those states.
class _ScriptedApi extends MockClaroPulseApi {
  _ScriptedApi({this.failDevices = false, this.noDevices = false}) : super(latency: Duration.zero);

  bool failDevices;
  final bool noDevices;
  int deviceCalls = 0;
  final Map<String, int> statusCalls = {};

  @override
  Future<DeviceStatus> getDeviceStatus(String deviceId) {
    statusCalls[deviceId] = (statusCalls[deviceId] ?? 0) + 1;
    return super.getDeviceStatus(deviceId);
  }

  @override
  Future<List<MyDevice>> listMyDevices() async {
    deviceCalls++;
    if (failDevices) throw const ApiException(message: 'Server unavailable');
    if (noDevices) return const [];
    return super.listMyDevices();
  }
}

Future<void> _pumpHome(WidgetTester tester, ClaroPulseApi api, {VoidCallback? onLogout}) async {
  final store = TokenStore();
  await store.load();
  await store.saveSession(accessToken: 'a', refreshToken: 'r', phone: '9876543210');
  final services = AppServices(tokenStore: store, sessionExpiry: SessionExpiry(), api: api, isMock: true);
  await tester.pumpWidget(MaterialApp(
    theme: ClaroTheme.dark,
    home: HomeScreen(services: services, onLogout: onLogout ?? () {}),
  ));
  await _settle(tester);
}

/// The running pump's hero card animates forever, so `pumpAndSettle` would
/// never return while the Home tab shows it. Pump a fixed time instead.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  testWidgets('header, four tabs, and the first device status load', (tester) async {
    await _pumpHome(tester, MockClaroPulseApi(latency: Duration.zero));

    expect(find.text('My Site'), findsOneWidget);
    expect(find.text('MOCK'), findsOneWidget);
    for (final tab in ['Home', 'Devices', 'Complaints', 'Profile']) {
      expect(find.text(tab), findsOneWidget);
    }
    expect(find.text('CP-PUMP-0142'), findsOneWidget);
    expect(find.text('Pump running'), findsOneWidget);
  });

  testWidgets('swiping the Home pager reaches the inverter and loads its status once', (tester) async {
    final api = _ScriptedApi();
    await _pumpHome(tester, api);
    expect(api.statusCalls, {'mock-pump-1': 1}, reason: 'page 0 is not fetched twice');

    await tester.fling(find.text('CP-PUMP-0142'), const Offset(-400, 0), 1000);
    await _settle(tester);
    expect(find.text('CP-INV-0087'), findsOneWidget);
    expect(find.text('Full readings coming soon'), findsOneWidget);
    expect(api.statusCalls, {'mock-pump-1': 1, 'mock-inverter-1': 1});

    // Swiping back reuses the pump's cached status.
    await tester.fling(find.text('CP-INV-0087'), const Offset(400, 0), 1000);
    await _settle(tester);
    expect(find.text('Pump running'), findsOneWidget);
    expect(api.statusCalls, {'mock-pump-1': 1, 'mock-inverter-1': 1});
  });

  testWidgets('switching tabs', (tester) async {
    var loggedOut = false;
    await _pumpHome(tester, MockClaroPulseApi(latency: Duration.zero), onLogout: () => loggedOut = true);

    await tester.tap(find.text('Devices'));
    await tester.pumpAndSettle();
    expect(find.text('CP-INV-0087'), findsOneWidget);
    expect(find.text('My Site'), findsNothing, reason: 'header shows on the Home tab only');

    await tester.tap(find.text('Complaints'));
    await tester.pumpAndSettle();
    expect(find.text('Coming soon.'), findsOneWidget);

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    expect(find.text('+91 9876543210'), findsOneWidget);
    await tester.tap(find.text('Log out'));
    expect(loggedOut, isTrue);
  });

  testWidgets('a device opens its detail overlay, and back returns to the tabs', (tester) async {
    await _pumpHome(tester, MockClaroPulseApi(latency: Duration.zero));
    await tester.tap(find.text('Devices'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('CP-INV-0087'));
    await tester.pumpAndSettle();
    expect(
      find.text('Historical charts will appear here once this device starts reporting extended telemetry.'),
      findsOneWidget,
    );
    expect(find.text('Your devices'), findsNothing, reason: 'the detail screen replaces the tabs');

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.text('CP-INV-0087'), findsOneWidget);
  });

  testWidgets('add device goes to scan, manual entry, and back', (tester) async {
    await _pumpHome(tester, MockClaroPulseApi(latency: Duration.zero));
    await tester.tap(find.text('Devices'));
    await tester.pumpAndSettle();

    // "Add a device" only appears in the empty state; with devices, it is the header button.
    await tester.tap(find.byTooltip('Add device'));
    await tester.pumpAndSettle();
    expect(find.text('Scan device QR'), findsOneWidget);

    await tester.tap(find.text('Enter ID manually'));
    await tester.pumpAndSettle();
    expect(find.text('Enter device ID'), findsOneWidget);

    // Back from manual entry returns to the scanner, not the tabs.
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.text('Scan device QR'), findsOneWidget);
  });

  testWidgets('a failed device list shows the error, and retry recovers', (tester) async {
    final api = _ScriptedApi(failDevices: true);
    await _pumpHome(tester, api);
    expect(find.text('Server unavailable'), findsOneWidget);

    api.failDevices = false;
    await tester.tap(find.text('Try again'));
    await _settle(tester);
    expect(find.text('CP-PUMP-0142'), findsOneWidget);
    expect(api.deviceCalls, 2);
  });

  testWidgets('an empty account shows the empty state, not an error', (tester) async {
    await _pumpHome(tester, _ScriptedApi(noDevices: true));
    expect(find.text('No devices yet'), findsOneWidget);
  });
}
