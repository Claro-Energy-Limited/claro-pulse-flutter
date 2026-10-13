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
    api: MockClaroPulseApi(latency: Duration.zero),
    isMock: true,
  );
}

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  testWidgets('full sign-in with the mock API, then log out', (tester) async {
    await tester.pumpWidget(const ClaroPulseApp(createServices: _mockServices));
    await tester.pumpAndSettle();

    // Phone step.
    expect(find.text('Sign in'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '9876543210');
    await tester.pump();
    await tester.tap(find.text('Send code'));
    await tester.pumpAndSettle();

    // Code step, with the mock hint and resend cooldown.
    expect(find.text('Enter the code'), findsOneWidget);
    expect(find.text('We sent a 6-digit code to +91 9876543210'), findsOneWidget);
    expect(find.text('Mock mode: use code 123456'), findsOneWidget);
    expect(find.text('Resend in 30s'), findsOneWidget);

    // A wrong code shows the server's message.
    await tester.enterText(find.byType(TextField), '000000');
    await tester.pump();
    await tester.tap(find.text('Verify'));
    await tester.pumpAndSettle();
    expect(find.text('The code is invalid or has expired.'), findsOneWidget);

    // The right code signs in.
    await tester.enterText(find.byType(TextField), '123456');
    await tester.pump();
    await tester.tap(find.text('Verify'));
    await tester.pumpAndSettle();
    expect(find.text("You're signed in"), findsOneWidget);

    // After the confirmation beat, home appears with the account's first device.
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(find.text('My Site'), findsOneWidget);
    expect(find.text('CP-PUMP-0142'), findsOneWidget);

    // Profile shows the number; Log out returns to the sign-in screen.
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    expect(find.text('+91 9876543210'), findsOneWidget);
    await tester.tap(find.text('Log out'));
    await tester.pumpAndSettle();
    expect(find.text('Sign in'), findsOneWidget);
  });

  testWidgets('a saved session skips sign-in', (tester) async {
    FlutterSecureStorage.setMockInitialValues({
      'access_token': 'a',
      'refresh_token': 'r',
      'phone': '9000000001',
    });
    await tester.pumpWidget(const ClaroPulseApp(createServices: _mockServices));
    await tester.pumpAndSettle();

    expect(find.text('My Site'), findsOneWidget);
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    expect(find.text('+91 9000000001'), findsOneWidget);
  });

  testWidgets('an expired session drops back to sign-in', (tester) async {
    FlutterSecureStorage.setMockInitialValues({'access_token': 'a', 'refresh_token': 'r'});
    late AppServices services;
    Future<AppServices> create() async => services = await _mockServices();

    await tester.pumpWidget(ClaroPulseApp(createServices: create));
    await tester.pumpAndSettle();
    expect(find.text('My Site'), findsOneWidget);

    services.sessionExpiry.signalExpired();
    await tester.pumpAndSettle();
    expect(find.text('Sign in'), findsOneWidget);
    expect(services.sessionExpiry.expired.value, isFalse);
  });
}
