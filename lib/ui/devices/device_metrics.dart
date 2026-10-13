import 'package:intl/intl.dart';

import '../../core/api/models/device_models.dart';
import '../../core/util/relative_time.dart';
import '../components/device_hero_card.dart';
import 'device_kind.dart';

// Ported from the Kotlin `DeviceMetrics.kt`: the one place that turns a
// `DeviceStatus` + `DeviceKind` into what `DeviceHeroCard` shows. Home and the
// detail screen both use it, so a device can never show two different sets of
// numbers.

String _format(double? value, int decimals) => value == null ? noData : value.toStringAsFixed(decimals);

/// Always exactly 4 callouts, in top-left, top-right, bottom-left, bottom-right
/// order.
///
/// Pump: live solar, flow, motor speed and head. Motor power is deliberately NOT
/// shown: its unit is unconfirmed on the server.
///
/// Inverter: real labels, every value [noData]. No inverter telemetry exists
/// yet, and numbers are never faked.
List<HeroCallout> heroCalloutsFor(DeviceKind kind, DeviceStatus? status) {
  switch (kind) {
    case DeviceKind.pump:
      final live = status?.live;
      return [
        HeroCallout(label: 'Solar', value: _format(live?.solarPowerKw, 1), unit: 'kW'),
        HeroCallout(label: 'Flow', value: _format(live?.flowRateLpm, 0), unit: 'LPM'),
        HeroCallout(label: 'Motor', value: _format(live?.motorSpeedRpm, 0), unit: 'RPM'),
        HeroCallout(label: 'Head', value: _format(live?.workingHeadM, 1), unit: 'm'),
      ];
    case DeviceKind.inverter:
      return const [
        HeroCallout(label: 'Solar', value: noData, unit: 'kW'),
        HeroCallout(label: 'Grid', value: noData, unit: 'kW'),
        HeroCallout(label: 'Battery', value: noData, unit: '%'),
        HeroCallout(label: 'Load', value: noData, unit: 'kW'),
      ];
  }
}

/// "What it has done today", shown under the hero diagram. Empty for an
/// inverter, which has no totals yet.
List<HeroMetric> heroTodaySummaryFor(DeviceKind kind, DeviceStatus? status) {
  switch (kind) {
    case DeviceKind.pump:
      final today = status?.today;
      return [
        HeroMetric(label: 'Run Hours Today', value: _format(today?.runHours, 1), unit: 'hrs'),
        HeroMetric(label: 'Energy Today', value: _format(today?.energyKwh, 1), unit: 'kWh'),
      ];
    case DeviceKind.inverter:
      return const [];
  }
}

/// The three activity series the detail screen can chart.
enum ActivitySeries {
  runHours('Run Hours', 'hrs'),
  energy('Energy', 'kWh'),
  water('Water', 'L');

  const ActivitySeries(this.label, this.unit);

  final String label;
  final String unit;

  double? valueOf(ActivityPoint p) => switch (this) {
        ActivitySeries.runHours => p.runHours,
        ActivitySeries.energy => p.energyKwh,
        ActivitySeries.water => p.waterLiters,
      };
}

/// One value per point. Nulls stay null: the chart draws them as gaps.
List<double?> activityChartValues(List<ActivityPoint> points, ActivitySeries series) =>
    points.map(series.valueOf).toList();

/// Three x-axis labels (first, middle, last) in local time. An unparseable
/// timestamp becomes an empty label rather than a raw ISO string.
List<String> activityChartLabels(List<ActivityPoint> points, ActivityRange range) {
  if (points.isEmpty) return const [];
  final indices = <int>{0, points.length ~/ 2, points.length - 1}.toList()..sort();
  final format = DateFormat(
    switch (range) {
      ActivityRange.day => 'h a',
      ActivityRange.week => 'EEE',
      ActivityRange.month => 'MMM d',
    },
    'en_US',
  );
  return [
    for (final i in indices)
      switch (parseActivityBucketStart(points[i].bucketStart)) {
        final parsed? => format.format(parsed.toLocal()),
        null => '',
      },
  ];
}
