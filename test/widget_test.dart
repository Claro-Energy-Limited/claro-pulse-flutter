import 'package:flutter_test/flutter_test.dart';

import 'package:claropulse/main.dart';

void main() {
  testWidgets('theme check screen renders', (tester) async {
    await tester.pumpWidget(const ClaroPulseApp(signedIn: false));

    expect(find.text('Claro Pulse'), findsOneWidget);
    expect(find.text('288.0 L/min'), findsOneWidget);
    expect(find.text('Signed in: no'), findsOneWidget);
  });
}
