import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:claropulse/app/theme/claro_theme.dart';
import 'package:claropulse/core/api/mock_claro_pulse_api.dart';
import 'package:claropulse/core/api/models/device_models.dart';
import 'package:claropulse/ui/onboarding/camera_permission.dart';
import 'package:claropulse/ui/onboarding/device_claim_screen.dart';
import 'package:claropulse/ui/onboarding/manual_device_entry_screen.dart';
import 'package:claropulse/ui/onboarding/qr_scanner_screen.dart';

class _FakePermission implements CameraPermission {
  _FakePermission(this.current);

  CameraAccess current;
  final CameraAccess afterRequest = CameraAccess.granted;
  int requests = 0;
  int settingsOpened = 0;

  @override
  Future<CameraAccess> check() async => current;

  @override
  Future<CameraAccess> request() async {
    requests++;
    return current = afterRequest;
  }

  @override
  Future<void> openSettings() async => settingsOpened++;
}

/// Records what was submitted, on top of the normal mock behaviour.
class _SpyApi extends MockClaroPulseApi {
  _SpyApi() : super(latency: Duration.zero);

  String? identifier;
  String? proof;

  @override
  Future<DeviceClaim> submitDeviceClaim({
    required String deviceIdentifier,
    required String proofReference,
  }) {
    identifier = deviceIdentifier;
    proof = proofReference;
    return super.submitDeviceClaim(deviceIdentifier: deviceIdentifier, proofReference: proofReference);
  }
}

Widget _app(Widget child) => MaterialApp(theme: ClaroTheme.dark, home: child);

/// Stands in for the camera: a button that "scans" a fixed code.
Widget _fakeCamera(BuildContext context, ValueChanged<String> onCode) => Center(
      child: TextButton(onPressed: () => onCode('861236078001482'), child: const Text('fake scan')),
    );

void main() {
  group('QR scanner', () {
    testWidgets('asks for camera access, then scans once', (tester) async {
      final permission = _FakePermission(CameraAccess.denied);
      final scanned = <String>[];
      await tester.pumpWidget(_app(QrScannerScreen(
        onScanned: scanned.add,
        onEnterManually: () {},
        onClose: () {},
        permission: permission,
        scannerBuilder: _fakeCamera,
      )));
      await tester.pumpAndSettle();

      expect(find.text('Camera access needed'), findsOneWidget);
      await tester.tap(find.text('Allow camera access'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(permission.requests, 1);
      expect(find.text('Scanning…'), findsOneWidget);

      await tester.tap(find.text('fake scan'));
      await tester.pump();
      await tester.tap(find.text('fake scan'));
      await tester.pump();
      expect(scanned, ['861236078001482'], reason: 'only the first scan counts');
      expect(find.text('Scanned'), findsOneWidget);
    });

    testWidgets('permanently denied offers Settings, and manual entry still works', (tester) async {
      final permission = _FakePermission(CameraAccess.permanentlyDenied);
      var manual = 0;
      var closed = 0;
      await tester.pumpWidget(_app(QrScannerScreen(
        onScanned: (_) {},
        onEnterManually: () => manual++,
        onClose: () => closed++,
        permission: permission,
        scannerBuilder: _fakeCamera,
      )));
      await tester.pumpAndSettle();

      expect(find.textContaining('turn it on in Settings'), findsOneWidget);
      await tester.tap(find.text('Open Settings'));
      expect(permission.settingsOpened, 1);

      await tester.tap(find.text('Enter device ID manually instead'));
      expect(manual, 1);
      await tester.tap(find.byTooltip('Close'));
      expect(closed, 1);
    });

    testWidgets('uses the test override when no permission is passed', (tester) async {
      QrScannerScreen.permissionOverride = const FixedCameraPermission(CameraAccess.denied);
      addTearDown(() => QrScannerScreen.permissionOverride = null);
      await tester.pumpWidget(_app(QrScannerScreen(
        onScanned: (_) {},
        onEnterManually: () {},
        onClose: () {},
      )));
      await tester.pumpAndSettle();
      expect(find.text('Camera access needed'), findsOneWidget);
    });
  });

  group('Manual entry', () {
    testWidgets('digits only, 6 to 16, then submits', (tester) async {
      String? submitted;
      await tester.pumpWidget(_app(ManualDeviceEntryScreen(onSubmit: (v) => submitted = v, onBack: () {})));

      await tester.enterText(find.byType(TextField), '12a34');
      await tester.pump();
      await tester.tap(find.text('Continue'));
      expect(submitted, isNull, reason: 'fewer than 6 digits');

      await tester.enterText(find.byType(TextField), '86123607800148299999');
      await tester.pump();
      await tester.tap(find.text('Continue'));
      expect(submitted, '8612360780014829', reason: 'capped at 16 digits');
    });

    testWidgets('back button', (tester) async {
      var back = 0;
      await tester.pumpWidget(_app(ManualDeviceEntryScreen(onSubmit: (_) {}, onBack: () => back++)));
      await tester.tap(find.byTooltip('Back'));
      expect(back, 1);
    });
  });

  group('Claim', () {
    testWidgets('submits with the right proof note and shows pending review', (tester) async {
      final api = _SpyApi();
      var done = 0;
      await tester.pumpWidget(_app(DeviceClaimScreen(
        scannedValue: '861236078001482',
        enteredManually: false,
        api: api,
        onSubmitted: () => done++,
        onBack: () {},
      )));

      expect(find.text('Add this device?'), findsOneWidget);
      expect(find.text('861236078001482'), findsOneWidget);
      await tester.tap(find.text('Submit for review'));
      await tester.pumpAndSettle();

      expect(api.identifier, '861236078001482');
      expect(api.proof, DeviceClaimScreen.proofScanned);
      expect(find.text('Submitted for review'), findsOneWidget);
      expect(find.byTooltip('Back'), findsNothing);

      await tester.tap(find.text('Done'));
      expect(done, 1);
    });

    testWidgets('manual entries are labelled as manual', (tester) async {
      final api = _SpyApi();
      await tester.pumpWidget(_app(DeviceClaimScreen(
        scannedValue: '123456',
        enteredManually: true,
        api: api,
        onSubmitted: () {},
        onBack: () {},
      )));
      await tester.tap(find.text('Submit for review'));
      await tester.pumpAndSettle();
      expect(api.proof, DeviceClaimScreen.proofManual);
    });

    testWidgets('a server error is shown and the form stays', (tester) async {
      await tester.pumpWidget(_app(DeviceClaimScreen(
        scannedValue: '   ',
        enteredManually: true,
        api: MockClaroPulseApi(latency: Duration.zero),
        onSubmitted: () {},
        onBack: () {},
      )));
      await tester.tap(find.text('Submit for review'));
      await tester.pumpAndSettle();
      expect(find.text('Enter the device ID.'), findsOneWidget);
      expect(find.text('Add this device?'), findsOneWidget);
    });
  });
}
