import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:claropulse/app/claro_pulse_app.dart';
import 'package:claropulse/core/api/mock_claro_pulse_api.dart';
import 'package:claropulse/core/auth/session_expiry.dart';
import 'package:claropulse/core/auth/token_store.dart';
import 'package:claropulse/core/services.dart';

Future<AppServices> _mockServices() async {
  final store = TokenStore();
  await store.load();
  return AppServices(
    tokenStore: store,
    sessionExpiry: SessionExpiry(),
    api: MockClaroPulseApi(latency: Duration.zero, confirmDelay: Duration.zero),
    isMock: true,
  );
}

Future<void> _frames(WidgetTester tester, [int n = 10]) async {
  for (var i = 0; i < n; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void _tallScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(430, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  testWidgets('sign in with the mock, reach home, then log out', (tester) async {
    _tallScreen(tester);
    await tester.pumpWidget(const ClaroPulseApp(createServices: _mockServices, minSplash: Duration.zero));
    await tester.pumpAndSettle();

    expect(find.text('Sign in'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '9876543210');
    await tester.pump();
    await tester.tap(find.text('Send code'));
    await tester.pumpAndSettle();

    expect(find.text('Mock mode: use code 123456'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '000000');
    await tester.pump();
    await tester.tap(find.text('Verify'));
    await tester.pumpAndSettle();
    expect(find.text('The code is invalid or has expired.'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '123456');
    await tester.pump();
    await tester.tap(find.text('Verify'));
    await tester.pumpAndSettle();
    expect(find.text("You're signed in"), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));
    await _frames(tester);
    expect(find.text('Water pumped today'), findsOneWidget);

    await tester.tap(find.text('Profile'));
    await _frames(tester);
    expect(find.text('+91 9876543210'), findsOneWidget);
    await tester.tap(find.text('Log out'));
    await _frames(tester, 5);
    await tester.tap(find.text('Log out').last);
    await _frames(tester);
    expect(find.text('Sign in'), findsOneWidget);
  });

  testWidgets('a saved session skips sign-in', (tester) async {
    _tallScreen(tester);
    FlutterSecureStorage.setMockInitialValues({'access_token': 'a', 'refresh_token': 'r', 'phone': '9000000001'});
    await tester.pumpWidget(const ClaroPulseApp(createServices: _mockServices, minSplash: Duration.zero));
    await _frames(tester);
    expect(find.text('Water pumped today'), findsOneWidget);
  });

  testWidgets('an expired session drops back to sign-in', (tester) async {
    _tallScreen(tester);
    FlutterSecureStorage.setMockInitialValues({'access_token': 'a', 'refresh_token': 'r'});
    late AppServices services;
    Future<AppServices> create() async => services = await _mockServices();

    await tester.pumpWidget(ClaroPulseApp(createServices: create, minSplash: Duration.zero));
    await _frames(tester);
    expect(find.text('Water pumped today'), findsOneWidget);

    services.sessionExpiry.signalExpired();
    await _frames(tester);
    expect(find.text('Sign in'), findsOneWidget);
  });

  testWidgets('the splash shows first', (tester) async {
    _tallScreen(tester);
    await tester.pumpWidget(const ClaroPulseApp(createServices: _mockServices));
    await tester.pump();
    expect(find.text('Smart solar pumping'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    await _frames(tester, 5);
    expect(find.text('Sign in'), findsOneWidget);
  });
}
