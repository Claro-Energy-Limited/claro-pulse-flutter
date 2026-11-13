import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:claropulse/core/models/smartnet_models.dart';

void main() {
  group('SmartnetModels Parsing', () {
    test('SmartnetLatestReading parses double-encoded extractedData correctly', () {
      final jsonRaw = {
        "createdAt": "2026-11-12 14:36:00",
        "sno": "S2SEG1240027560",
        "extractedData": jsonEncode({
          "d_type": "SEG1",
          "dc": false,
          "dcov": "0",
          "dcuv": 0,
          "dcv": "398.9",
          "ef": "false",
          "ep": 972,
          "gHz": 50.01,
          "gv": 253.8,
          "ii": "3.83",
          "iv": 255,
          "irs": "1",
          "grs": true,
          "pvp": 1071,
          "rat": "125V / 76VA",
          "tskWh": "1199",
          "custom_undocumented_key": "abc123"
        })
      };

      final r = SmartnetLatestReading.fromJson(jsonRaw);
      expect(r.sno, 'S2SEG1240027560');
      expect(r.createdAt, DateTime.utc(2026, 11, 12, 14, 36));
      expect(r.dcv, 398.9);
      expect(r.iv, 255.0);
      expect(r.ii, 3.83);
      expect(r.pvp, 1071.0);
      expect(r.tskWh, 1199.0);
      expect(r.irs, isTrue); // "1" -> true
      expect(r.grs, isTrue); // true -> true
      expect(r.dc, isFalse); // false -> false
      expect(r.dcov, isFalse); // "0" -> false
      expect(r.dcuv, isFalse); // 0 -> false
      expect(r.ef, isFalse); // "false" -> false
      expect(r.outputPowerWatts, closeTo(255.0 * 3.83, 0.01));
      expect(r.undocumentedFields['custom_undocumented_key'], 'abc123');
    });

    test('outputPowerWatts calculates iv * ii when irs is true, 0 when irs is false', () {
      final rRunning = SmartnetLatestReading(
        createdAt: DateTime.now(),
        sno: 'S1',
        iv: 230,
        ii: 10,
        irs: true,
      );
      expect(rRunning.outputPowerWatts, 2300.0);

      final rStopped = SmartnetLatestReading(
        createdAt: DateTime.now(),
        sno: 'S1',
        iv: 230,
        ii: 10,
        irs: false,
      );
      expect(rStopped.outputPowerWatts, 0.0);
    });

    test('SmartnetTodayGraph parses correctly', () {
      final jsonRaw = {
        "sno": "S2SEG1240027560",
        "statusCode": 0,
        "summary": {
          "todayGen": "8",
          "totalGen": 1199,
          "totalCuf": "15.65"
        },
        "data": [
          {
            "timestamp": "2026-11-12 06:33:48",
            "pvp": "40",
            "todayGen": 0,
            "cumulativeGen": 1191,
            "label": "06:33"
          }
        ]
      };

      final graph = SmartnetTodayGraph.fromJson(jsonRaw);
      expect(graph.sno, 'S2SEG1240027560');
      expect(graph.todayGen, 8.0);
      expect(graph.totalGen, 1199.0);
      expect(graph.totalCuf, 15.65);
      expect(graph.points.length, 1);
      expect(graph.points.first.pvp, 40.0);
      expect(graph.points.first.label, '06:33');
    });

    test('Smartnet7DaysHistory handles array parsing with missing values', () {
      final jsonRaw = {
        "createdAt": ["2026-11-06T12:12:00.116Z", "2026-11-07T11:38:44.293Z"],
        "tskWh": [622, 630],
        "dkWh": [7, "8"],
        "labels": ["Fri, 06/11", "Sat, 07/11"]
      };

      final history = Smartnet7DaysHistory.fromJson(jsonRaw);
      expect(history.points.length, 2);
      expect(history.points[0].dkWh, 7.0);
      expect(history.points[1].dkWh, 8.0);
      expect(history.points[0].label, 'Fri, 06/11');
    });
  });
}
