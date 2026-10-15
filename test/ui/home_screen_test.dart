import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:claropulse/app/theme/claro_palette.dart';
import 'package:claropulse/app/theme/claro_theme.dart';
import 'package:claropulse/core/api/api_exception.dart';
import 'package:claropulse/core/api/claro_pulse_api.dart';
import 'package:claropulse/core/api/mock_claro_pulse_api.dart';
import 'package:claropulse/core/api/models/device_models.dart';
import 'package:claropulse/core/auth/session_expiry.dart';
import 'package:claropulse/core/auth/token_store.dart';
import 'package:claropulse/core/services.dart';
import 'package:claropulse/core/settings/app_settings.dart';
import 'package:claropulse/ui/home/home_screen.dart';
import 'package:claropulse/ui/onboarding/camera_permission.dart';
import 'package:claropulse/ui/onboarding/qr_scanner_screen.dart';

/// The mock with scripted device-list and status behaviour.
class _ScriptedApi extends MockClaroPulseApi {
  _ScriptedApi({this.failDevices = false, this.noDevices = false, this.dryRun = false})
      : super(latency: Duration.zero, confirmDelay: Duration.zero);

  final bool failDevices;
  final bool noDevices;
  final bool dryRun;

  @override
  Future<List<MyDevice>> listMyDevices() async {
    if (failDevices) throw const ApiException(message: 'Server unavailable');
    if (noDevices) return const [];
    return super.listMyDevices();
  }

  @override
  Future<DeviceStatus> getDeviceStatus(String deviceId) async {
    final real = await super.getDeviceStatus(deviceId);
    if (!dryRun || deviceId != MockClaroPulseApi.pumpId) return real;
    return DeviceStatus(
      deviceId: real.deviceId,
      deviceUid: real.deviceUid,
      runStatus: 'STOPPED',
      connectionStatus: 'ONLINE',
      lastReportedAt: real.lastReportedAt,
      today: real.today,
      live: const LiveReadings(solarPowerKw: 5.0, flowRateLpm: 0, motorSpeedRpm: 0),
      faultText: null,
      protections: const Protections(dryRun: true, waterLevelLow: false),
    );
  }
}

/// Lets frames run without waiting for endless animations (a running pump's
/// pulsing dot never "settles").
Future<void> _settle(WidgetTester tester, [int frames = 10]) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _pumpHome(
  WidgetTester tester,
  ClaroPulseApi api, {
  VoidCallback? onLogout,
  AppSettings? settings,
}) async {
  tester.view.physicalSize = const Size(430, 3200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final store = TokenStore();
  await store.load();
  await store.saveSession(accessToken: 'a', refreshToken: 'r', phone: '9876543210');
  final services = AppServices(
    tokenStore: store,
    sessionExpiry: SessionExpiry(),
    api: api,
    isMock: true,
    settings: settings,
  );
  await tester.pumpWidget(MaterialApp(
    theme: ClaroTheme.dark,
    home: HomeScreen(
      services: services,
      onLogout: onLogout ?? () {},
      confirmPollInterval: const Duration(milliseconds: 100),
    ),
  ));
  await _settle(tester);
}

MockClaroPulseApi _mock() => MockClaroPulseApi(latency: Duration.zero, confirmDelay: Duration.zero);

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  testWidgets('home shows the pump, water today and the controls', (tester) async {
    await _pumpHome(tester, _mock());

    expect(find.text('Solar Pump'), findsOneWidget);
    expect(find.text('CP-PUMP-0142'), findsOneWidget);
    expect(find.text('Water pumped today'), findsOneWidget);
    expect(find.text('Running'), findsOneWidget);
    expect(find.text('Stop pump'), findsOneWidget);
    for (final tab in ['Home', 'Usage', 'Complaints', 'Profile']) {
      expect(find.text(tab), findsOneWidget);
    }
  });

  testWidgets('stopping asks first, waits for the pump, then confirms', (tester) async {
    await _pumpHome(tester, _mock());

    await tester.tap(find.text('Stop pump'));
    await _settle(tester, 5);
    expect(find.text('Stop the pump?'), findsOneWidget);
    expect(find.text('Demo mode: no real pump is controlled.'), findsOneWidget);

    await tester.tap(find.text('Stop pump').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('Stopping pump…'), findsOneWidget);

    await _settle(tester, 5);
    expect(find.text('Start pump'), findsOneWidget);
    expect(find.text('Stopped'), findsOneWidget);
    expect(find.text('Last run'), findsOneWidget);
    expect(find.text('litres pumped'), findsOneWidget);

    // The finished run gets its story.
    expect(find.text('Run complete'), findsOneWidget);
    await tester.tap(find.text('Done'));
    await _settle(tester, 5);
    expect(find.text('Run complete'), findsNothing);
  });

  testWidgets('cancelling the sheet changes nothing', (tester) async {
    await _pumpHome(tester, _mock());
    await tester.tap(find.text('Stop pump'));
    await _settle(tester, 5);
    await tester.tap(find.text('Cancel'));
    await _settle(tester, 5);
    expect(find.text('Running'), findsOneWidget);
    expect(find.text('Stopping pump…'), findsNothing);
  });

  testWidgets('start is blocked with a reason when the well may be dry', (tester) async {
    await _pumpHome(tester, _ScriptedApi(dryRun: true));

    expect(find.text('Needs attention'), findsOneWidget);
    await tester.tap(find.text('Start pump'));
    await _settle(tester, 5);
    expect(find.text('Start the pump?'), findsOneWidget);
    expect(find.textContaining('Dry-run protection is on'), findsOneWidget);

    await tester.tap(find.text('Start pump').last);
    await _settle(tester, 5);
    expect(find.text('Start the pump?'), findsOneWidget, reason: 'disabled button does nothing');
  });

  testWidgets('switching to the inverter', (tester) async {
    await _pumpHome(tester, _mock());

    await tester.tap(find.text('Solar Pump'));
    await _settle(tester, 5);
    await tester.tap(find.text('Solar Inverter'));
    await _settle(tester);

    expect(find.text('CP-INV-0087'), findsOneWidget);
    expect(find.text('Readings coming soon'), findsOneWidget);
    expect(find.text('Start pump'), findsNothing);
    expect(find.text('Stop pump'), findsNothing);
  });

  testWidgets('pump details', (tester) async {
    await _pumpHome(tester, _mock());

    // Tapping the pump on Home opens its details.
    await tester.tap(find.byKey(const ValueKey('device-hero')));
    await _settle(tester);
    expect(find.text('Pump details'), findsOneWidget);
    expect(find.text('Claro SP-5 Solar Surface Pump'), findsOneWidget);
    expect(find.text('861236078001482'), findsOneWidget);
    expect(find.text('STACON VFD 5.5 kW'), findsOneWidget);
    expect(find.text('Under warranty'), findsOneWidget);

    await tester.tap(find.byTooltip('Back'));
    await _settle(tester);
    expect(find.text('Water pumped today'), findsOneWidget);
  });

  testWidgets('alerts show a badge until opened', (tester) async {
    await _pumpHome(tester, _mock());
    expect(find.text('3'), findsOneWidget);

    await tester.tap(find.byTooltip('Alerts'));
    await _settle(tester);
    expect(find.text('Pump paused: low water'), findsOneWidget);

    expect(find.text("Yesterday's summary"), findsOneWidget);

    await tester.tap(find.byTooltip('Back'));
    await _settle(tester);
    expect(find.text('3'), findsNothing);
  });

  testWidgets('bluetooth connects (simulated)', (tester) async {
    await _pumpHome(tester, _mock());

    await tester.tap(find.byTooltip('Bluetooth'));
    await _settle(tester, 5);
    expect(find.text('Bluetooth control'), findsOneWidget);
    await tester.tap(find.text('Connect to CP-PUMP-0142'));
    await tester.pump();
    expect(find.text('Looking for your pump nearby…'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1600));
    await _settle(tester, 3);
    expect(find.text('Connected to CP-PUMP-0142'), findsOneWidget);
  });

  testWidgets('raise a complaint and see it listed', (tester) async {
    await _pumpHome(tester, _mock());

    await tester.tap(find.text('Complaints'));
    await _settle(tester);
    expect(find.text('CP-1038'), findsOneWidget);
    expect(find.text('In progress'), findsOneWidget);

    await tester.tap(find.text('Raise a complaint'));
    await _settle(tester);
    await tester.tap(find.text('Low water flow'));
    await tester.enterText(find.byType(TextField), 'Very little water since this morning');
    await tester.pump();
    await tester.tap(find.text('Submit complaint'));
    await _settle(tester);

    expect(find.text('Complaint raised'), findsOneWidget);
    expect(find.text('Ticket CP-1044'), findsOneWidget);

    await tester.tap(find.text('Done'));
    await _settle(tester);
    expect(find.text('CP-1044'), findsOneWidget);
    expect(find.text('Open'), findsOneWidget);
  });

  testWidgets('usage tab shows totals and switches range', (tester) async {
    await _pumpHome(tester, _mock());

    await tester.tap(find.text('Usage'));
    await _settle(tester);
    expect(find.text('Water usage'), findsOneWidget);
    expect(find.text('Total water'), findsOneWidget);
    expect(find.text('So far today'), findsOneWidget);

    await tester.tap(find.text('This week'));
    await _settle(tester);
    expect(find.textContaining('litres a day'), findsOneWidget);
  });

  testWidgets('profile shows the number and logs out after confirming', (tester) async {
    var loggedOut = false;
    await _pumpHome(tester, _mock(), onLogout: () => loggedOut = true);

    await tester.tap(find.text('Profile'));
    await _settle(tester);
    expect(find.text('+91 9876543210'), findsOneWidget);

    await tester.tap(find.text('Log out'));
    await _settle(tester, 5);
    expect(find.text('Log out?'), findsOneWidget);
    await tester.tap(find.text('Log out').last);
    await _settle(tester, 5);
    expect(loggedOut, isTrue);
  });

  testWidgets('add a device from the device switcher opens the scanner', (tester) async {
    QrScannerScreen.permissionOverride = const FixedCameraPermission(CameraAccess.denied);
    addTearDown(() => QrScannerScreen.permissionOverride = null);
    await _pumpHome(tester, _mock());

    await tester.tap(find.text('Solar Pump'));
    await _settle(tester, 5);
    await tester.tap(find.text('Add a device'));
    await _settle(tester);
    expect(find.text('Camera access needed'), findsOneWidget);
  });

  testWidgets('an empty account shows the add-device state', (tester) async {
    await _pumpHome(tester, _ScriptedApi(noDevices: true));
    expect(find.text('No pump added yet'), findsOneWidget);
  });

  testWidgets('a failed device list shows an error with retry', (tester) async {
    await _pumpHome(tester, _ScriptedApi(failDevices: true));
    expect(find.text("Couldn't load your pumps"), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
  });

  testWidgets('home shows the running run, the ring and swipeable "for you" cards', (tester) async {
    await _pumpHome(tester, _mock());

    expect(find.text('Running now'), findsOneWidget);
    expect(find.text('litres so far'), findsOneWidget);
    expect(find.text('of a good day'), findsOneWidget);
    expect(find.text('RIGHT NOW'), findsOneWidget);

    // Most useful first: something to do, then a complaint update.
    expect(find.text('Clean your solar panels'), findsOneWidget);
    expect(find.text('Complaint CP-1038 updated'), findsOneWidget);

    // Swipe to the last card.
    for (var i = 0; i < 3; i++) {
      await tester.drag(find.byType(PageView), const Offset(-320, 0));
      await _settle(tester, 5);
    }
    expect(find.text('₹4,850 saved this month'), findsOneWidget);
  });

  testWidgets('tapping the run card opens its story', (tester) async {
    await _pumpHome(tester, _mock());
    await tester.tap(find.text('Running now'));
    await _settle(tester, 5);
    expect(find.text('litres so far'), findsNWidgets(2));
    await tester.tap(find.byTooltip('Close'));
    await _settle(tester, 5);
    expect(find.text('litres so far'), findsOneWidget);
  });

  testWidgets('"All runs" opens Usage with recent runs and the monthly report', (tester) async {
    await _pumpHome(tester, _mock());

    await tester.tap(find.text('All runs'));
    await _settle(tester);
    expect(find.text('Water usage'), findsOneWidget);
    expect(find.text('RECENT RUNS'), findsOneWidget);

    await tester.tap(find.text('Monthly report'));
    await _settle(tester);
    expect(find.text('Best day'), findsOneWidget);
    expect(find.text('Share report'), findsOneWidget);

    await tester.tap(find.byTooltip('Back'));
    await _settle(tester);
    expect(find.text('Water usage'), findsOneWidget);
  });

  testWidgets('appearance can be set to light, dark or system', (tester) async {
    final settings = AppSettings();
    await _pumpHome(tester, _mock(), settings: settings);

    await tester.tap(find.text('Profile'));
    await _settle(tester);
    expect(find.text('System default'), findsOneWidget);

    await tester.tap(find.text('Appearance'));
    await _settle(tester, 5);
    await tester.tap(find.text('Light'));
    await _settle(tester, 5);

    expect(settings.themeMode.value, ThemeMode.light);
    expect(find.text('Light'), findsOneWidget);

    await tester.tap(find.text('Appearance'));
    await _settle(tester, 5);
    await tester.tap(find.text('Sky'));
    await _settle(tester, 3);
    expect(settings.accent.value, ClaroAccent.sky);
  });
}
