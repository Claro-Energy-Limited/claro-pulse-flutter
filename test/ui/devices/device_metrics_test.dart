import 'package:flutter_test/flutter_test.dart';

import 'package:claropulse/core/api/models/device_models.dart';
import 'package:claropulse/ui/devices/device_kind.dart';
import 'package:claropulse/ui/devices/device_metrics.dart';

import 'device_test_data.dart';

/// A bucket at the given LOCAL time, sent as UTC like the server does.
ActivityPoint _point(DateTime local, {double? runHours}) =>
    ActivityPoint(bucketStart: local.toUtc().toIso8601String(), runHours: runHours);

void main() {
  group('heroCalloutsFor', () {
    test('pump formats and rounds each live reading', () {
      final status = testStatus(
        live: const LiveReadings(solarPowerKw: 5.24, flowRateLpm: 288.4, motorSpeedRpm: 2879.6, workingHeadM: 70),
      );
      final callouts = heroCalloutsFor(DeviceKind.pump, status);

      expect(callouts.map((c) => c.label), ['Solar', 'Flow', 'Motor', 'Head']);
      expect(callouts.map((c) => c.value), ['5.2', '288', '2880', '70.0']);
      expect(callouts.map((c) => c.unit), ['kW', 'LPM', 'RPM', 'm']);
    });

    test('pump with missing readings or no status shows noData, never zero', () {
      expect(heroCalloutsFor(DeviceKind.pump, testStatus()).map((c) => c.value), everyElement(noData));
      expect(heroCalloutsFor(DeviceKind.pump, null).map((c) => c.value), everyElement(noData));
      expect(heroCalloutsFor(DeviceKind.pump, null), hasLength(4));
    });

    test('inverter has real labels and every value noData', () {
      final callouts = heroCalloutsFor(DeviceKind.inverter, testStatus());
      expect(callouts.map((c) => c.label), ['Solar', 'Grid', 'Battery', 'Load']);
      expect(callouts.map((c) => c.unit), ['kW', 'kW', '%', 'kW']);
      expect(callouts.map((c) => c.value), everyElement(noData));
    });
  });

  group('heroTodaySummaryFor', () {
    test('pump shows run hours and energy to 1 decimal', () {
      final summary = heroTodaySummaryFor(
        DeviceKind.pump,
        testStatus(today: const TodayTotals(runHours: 4.25, energyKwh: 12.64)),
      );
      expect(summary.map((m) => m.label), ['Run Hours Today', 'Energy Today']);
      expect(summary.map((m) => m.value), ['4.3', '12.6']);
      expect(summary.map((m) => m.unit), ['hrs', 'kWh']);
    });

    test('pump with no totals shows noData', () {
      expect(heroTodaySummaryFor(DeviceKind.pump, null).map((m) => m.value), [noData, noData]);
    });

    test('inverter has no today summary', () {
      expect(heroTodaySummaryFor(DeviceKind.inverter, testStatus()), isEmpty);
    });
  });

  test('activityChartValues picks the series and keeps nulls as gaps', () {
    final points = [
      const ActivityPoint(bucketStart: 'a', runHours: 1, energyKwh: 2, waterLiters: 3),
      const ActivityPoint(bucketStart: 'b'),
    ];
    expect(activityChartValues(points, ActivitySeries.runHours), [1, null]);
    expect(activityChartValues(points, ActivitySeries.energy), [2, null]);
    expect(activityChartValues(points, ActivitySeries.water), [3, null]);
  });

  group('activityChartLabels', () {
    test('label counts: 24 points → 3, 1 → 1, 0 → 0', () {
      final start = DateTime(2026, 9, 10);
      List<ActivityPoint> hours(int n) => [for (var i = 0; i < n; i++) _point(start.add(Duration(hours: i)))];

      expect(activityChartLabels(hours(24), ActivityRange.day), hasLength(3));
      expect(activityChartLabels(hours(1), ActivityRange.day), hasLength(1));
      expect(activityChartLabels(const [], ActivityRange.day), isEmpty);
    });

    test('day labels are hours, first / middle / last', () {
      final start = DateTime(2026, 9, 10);
      final points = [for (var i = 0; i < 24; i++) _point(start.add(Duration(hours: i)))];
      expect(activityChartLabels(points, ActivityRange.day), ['12 AM', '12 PM', '11 PM']);
    });

    test('week labels are weekdays', () {
      // 2026-09-07 is a Monday.
      final points = [for (var d = 0; d < 7; d++) _point(DateTime(2026, 9, 7 + d))];
      expect(activityChartLabels(points, ActivityRange.week), ['Mon', 'Thu', 'Sun']);
    });

    test('month labels are month and day', () {
      final points = [for (var d = 0; d < 30; d++) _point(DateTime(2026, 9, 1 + d))];
      expect(activityChartLabels(points, ActivityRange.month), ['Sep 1', 'Sep 16', 'Sep 30']);
    });

    test('an unparseable timestamp becomes an empty label', () {
      final points = [
        const ActivityPoint(bucketStart: 'not a date'),
        _point(DateTime(2026, 9, 10, 6)),
        _point(DateTime(2026, 9, 10, 7)),
      ];
      expect(activityChartLabels(points, ActivityRange.day), ['', '6 AM', '7 AM']);
    });
  });
}
