import 'package:flutter_test/flutter_test.dart';
import 'package:claropulse/core/classifier/inverter_classifier.dart';
import 'package:claropulse/core/models/smartnet_models.dart';

void main() {
  final daylightNow = DateTime.utc(2026, 11, 12, 6, 0); // 11:30 IST (Daylight)
  final nightNow = DateTime.utc(2026, 11, 12, 17, 0); // 22:30 IST (Night)

  group('InverterClassifier', () {
    test('returns noData when reading is null', () {
      final res = InverterClassifier.classify(null);
      expect(res.kind, InverterStateKind.noData);
      expect(res.label, 'No data');
      expect(res.issues, isEmpty);
    });

    test('returns healthy when all flags OK and live telemetry normal in daylight', () {
      final r = SmartnetLatestReading(
        createdAt: daylightNow,
        sno: 'S2SEG1240027560',
        pvp: 1200,
        irs: true,
        grs: true,
        it: 45.0,
      );
      final res = InverterClassifier.classify(r, nowUtc: daylightNow);
      expect(res.kind, InverterStateKind.healthy);
      expect(res.label, 'Working well');
      expect(res.issues, isEmpty);
    });

    test('returns fault when gov (grid over voltage) active', () {
      final r = SmartnetLatestReading(
        createdAt: daylightNow,
        sno: 'S2SEG1250032185',
        gov: true,
      );
      final res = InverterClassifier.classify(r, nowUtc: daylightNow);
      expect(res.kind, InverterStateKind.fault);
      expect(res.issues.first.id, 'grid_voltage');
      expect(res.issues.first.title, 'Grid voltage out of range');
      expect(res.tryTheseFirst, isNotEmpty);
    });

    test('earth fault (ef) excludes restart step in tryTheseFirst', () {
      final r = SmartnetLatestReading(
        createdAt: daylightNow,
        sno: 'S2SEG1250032185',
        ef: true,
      );
      final res = InverterClassifier.classify(r, nowUtc: daylightNow);
      expect(res.kind, InverterStateKind.fault);
      expect(res.issues.first.id, 'ef');
      expect(res.issues.first.title, 'Earth fault');
      // Restart step should NOT be present for earth fault
      final hasRestart = res.tryTheseFirst.any((s) => s.contains('Restart:'));
      expect(hasRestart, isFalse);
    });

    test('returns warning for gof / guf when no fault present', () {
      final r = SmartnetLatestReading(
        createdAt: daylightNow,
        sno: 'S2SEG1240027863',
        gof: true,
      );
      final res = InverterClassifier.classify(r, nowUtc: daylightNow);
      expect(res.kind, InverterStateKind.warning);
      expect(res.label, 'Needs watching');
      expect(res.issues.first.id, 'grid_freq');
    });

    test('returns warning when temp >= 65 °C', () {
      final r = SmartnetLatestReading(
        createdAt: daylightNow,
        sno: 'S2SEG1240027863',
        it: 68.5,
      );
      final res = InverterClassifier.classify(r, nowUtc: daylightNow);
      expect(res.kind, InverterStateKind.warning);
      expect(res.issues.first.id, 'high_temp');
      expect(res.issues.first.title, 'Inverter too hot');
    });

    test('returns warning for stale data (> 45 min) during daylight', () {
      final staleTime = daylightNow.subtract(const Duration(minutes: 50));
      final r = SmartnetLatestReading(
        createdAt: staleTime,
        sno: 'S2SEG1240027863',
      );
      final res = InverterClassifier.classify(r, nowUtc: daylightNow);
      expect(res.kind, InverterStateKind.warning);
      expect(res.issues.first.id, 'stale_data');
      expect(res.issues.first.title, 'Monitoring link lost');
    });

    test('does NOT return warning for stale data outside daylight', () {
      final staleTime = nightNow.subtract(const Duration(minutes: 120));
      final r = SmartnetLatestReading(
        createdAt: staleTime,
        sno: 'S2SEG1240027863',
        pvp: 0,
      );
      final res = InverterClassifier.classify(r, nowUtc: nightNow);
      expect(res.kind, InverterStateKind.resting);
      expect(res.label, 'Resting, no sun');
    });

    test('returns resting outside daylight when no faults and low pvp', () {
      final r = SmartnetLatestReading(
        createdAt: nightNow,
        sno: 'S2SEG1240027560',
        pvp: 0,
      );
      final res = InverterClassifier.classify(r, nowUtc: nightNow);
      expect(res.kind, InverterStateKind.resting);
      expect(res.label, 'Resting, no sun');
    });
  });
}
