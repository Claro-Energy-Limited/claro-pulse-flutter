import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:claropulse/app/theme/claro_theme.dart';
import 'package:claropulse/ui/components/claro_line_chart.dart';
import 'package:claropulse/ui/components/claro_otp_row.dart';
import 'package:claropulse/ui/components/claro_primary_button.dart';
import 'package:claropulse/ui/components/device_hero_card.dart';
import 'package:claropulse/ui/devices/device_kind.dart';
import 'package:claropulse/ui/icons/claro_icons.dart';

Widget _host(Widget child) => MaterialApp(
      theme: ClaroTheme.dark,
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );

void main() {
  group('DeviceKind.from', () {
    test('maps INVERTER and folds everything else into pump', () {
      expect(DeviceKind.from('INVERTER'), DeviceKind.inverter);
      expect(DeviceKind.from('PUMP'), DeviceKind.pump);
      expect(DeviceKind.from('BATTERY'), DeviceKind.pump);
      expect(DeviceKind.from(null), DeviceKind.pump);
    });
  });

  testWidgets('OTP row keeps digits only, at most six', (tester) async {
    var value = '';
    await tester.pumpWidget(_host(StatefulBuilder(
      builder: (context, setState) => ClaroOtpRow(
        value: value,
        onChanged: (v) => setState(() => value = v),
      ),
    )));

    await tester.enterText(find.byType(TextField), '12a345678');
    await tester.pump();

    expect(value, '123456');
    for (final digit in ['1', '2', '3', '4', '5', '6']) {
      expect(find.text(digit), findsWidgets);
    }
  });

  testWidgets('primary button: enabled taps, disabled and loading do not', (tester) async {
    var taps = 0;
    await tester.pumpWidget(_host(Column(children: [
      ClaroPrimaryButton(text: 'Go', onPressed: () => taps++),
      ClaroPrimaryButton(text: 'Off', onPressed: () => taps++, enabled: false),
      ClaroPrimaryButton(text: 'Busy', onPressed: () => taps++, loading: true),
    ])));

    await tester.tap(find.text('Go'));
    await tester.tap(find.text('Off'));
    await tester.tap(find.byType(CircularProgressIndicator));
    expect(taps, 1);
  });

  testWidgets('line chart shows the empty message only without data', (tester) async {
    await tester.pumpWidget(_host(const ClaroLineChart(points: [null, null], xLabels: [])));
    expect(find.text('No data yet for this range'), findsOneWidget);

    await tester.pumpWidget(_host(const ClaroLineChart(points: [1, null, 3], xLabels: ['a', 'b'])));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('No data yet for this range'), findsNothing);
    expect(find.text('a'), findsOneWidget);
  });

  testWidgets('hero card shows callouts, labels in capitals, and the coming-soon tag', (tester) async {
    await tester.pumpWidget(_host(const DeviceHeroCard(
      kind: DeviceKind.inverter,
      isRunning: false,
      comingSoon: true,
      callouts: [
        HeroCallout(label: 'Solar', value: '5.4', unit: 'kW'),
        HeroCallout(label: 'Flow', value: noData, unit: 'L/min'),
        HeroCallout(label: 'Speed', value: '2880', unit: 'rpm'),
        HeroCallout(label: 'Head', value: '70', unit: 'm'),
      ],
      todaySummary: [HeroMetric(label: 'Water', value: '42,000', unit: 'L')],
    )));

    expect(find.text('5.4'), findsOneWidget);
    expect(find.text('SOLAR'), findsOneWidget);
    expect(find.text('Water'), findsOneWidget);
    expect(find.text('Full readings coming soon'), findsOneWidget);
  });

  testWidgets('a running pump card animates without errors', (tester) async {
    await tester.pumpWidget(_host(const DeviceHeroCard(
      kind: DeviceKind.pump,
      isRunning: true,
      callouts: [
        HeroCallout(label: 'A', value: '1', unit: 'x'),
        HeroCallout(label: 'B', value: '2', unit: 'x'),
        HeroCallout(label: 'C', value: '3', unit: 'x'),
        HeroCallout(label: 'D', value: '4', unit: 'x'),
      ],
      todaySummary: [],
    )));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Full readings coming soon'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('every icon paints without errors', (tester) async {
    await tester.pumpWidget(_host(const Wrap(children: [
      SolarPanelIcon(),
      BatteryIcon(),
      LoadIcon(),
      ClockIcon(),
      WaterDropIcon(),
      EvseIcon(),
      GridTowerIcon(),
      NavHomeIcon(),
      NavAnalyticsIcon(),
      NavGridIcon(),
      NavWalletIcon(),
      NavProfileIcon(),
    ])));
    expect(tester.takeException(), isNull);
  });
}
