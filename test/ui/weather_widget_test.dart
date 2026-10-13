import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:claropulse/app/theme/claro_theme.dart';
import 'package:claropulse/ui/weather/weather_widget.dart';

void main() {
  testWidgets('shows the sample weather', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: ClaroTheme.dark,
      home: const Scaffold(body: WeatherWidget(snapshot: WeatherSnapshot.sample)),
    ));
    // The sun animates forever, so pump a fixed time rather than settling.
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('31°C'), findsOneWidget);
    expect(find.text('Sunny'), findsOneWidget);
    expect(find.text('Good conditions for solar generation'), findsOneWidget);
  });
}
