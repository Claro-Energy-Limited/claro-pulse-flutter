import 'dart:convert';

/// Robust helper to parse a number from int, double or String.
double? parseDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  if (value is String) {
    return double.tryParse(value.trim());
  }
  return null;
}

/// Robust helper to parse boolean flags from bool, int (0/1), or String ("0"/"1", "true"/"false").
bool parseBool(dynamic value) {
  if (value == null) return false;
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final s = value.trim().toLowerCase();
    return s == 'true' || s == '1' || s == 'yes';
  }
  return false;
}

/// Decoded latest reading from `op=lat`.
class SmartnetLatestReading {
  SmartnetLatestReading({
    required this.createdAt,
    required this.sno,
    this.pvv,
    this.pvi,
    this.pvp,
    this.dcv,
    this.iv,
    this.ii,
    this.iHz,
    this.gv,
    this.gHz,
    this.it,
    this.ep,
    this.tskWh,
    this.tkWh,
    this.irs = false,
    this.grs = false,
    this.pfs = false,
    this.dType,
    this.rat,
    this.gov = false,
    this.guv = false,
    this.gof = false,
    this.guf = false,
    this.ioc = false,
    this.dc = false,
    this.tmp = false,
    this.pvov = false,
    this.pvuv = false,
    this.pvoc = false,
    this.dcov = false,
    this.dcuv = false,
    this.ef = false,
    this.undocumentedFields = const {},
  });

  final DateTime? createdAt;
  final String sno;

  final double? pvv;
  final double? pvi;
  final double? pvp;
  final double? dcv;
  final double? iv;
  final double? ii;
  final double? iHz;
  final double? gv;
  final double? gHz;
  final double? it;
  final double? ep;
  final double? tskWh;
  final double? tkWh;

  final bool irs;
  final bool grs;
  final bool pfs;

  final String? dType;
  final String? rat;

  // Fault flags
  final bool gov;
  final bool guv;
  final bool gof;
  final bool guf;
  final bool ioc;
  final bool dc;
  final bool tmp;
  final bool pvov;
  final bool pvuv;
  final bool pvoc;
  final bool dcov;
  final bool dcuv;
  final bool ef;

  final Map<String, dynamic> undocumentedFields;

  /// Calculated AC output power in Watts (iv * ii). Returns 0 when not running.
  double get outputPowerWatts {
    if (!irs) return 0.0;
    final v = iv ?? 0.0;
    final i = ii ?? 0.0;
    final calc = v * i;
    return calc < 0 ? 0.0 : calc;
  }

  factory SmartnetLatestReading.fromJson(Map<String, dynamic> json) {
    final rawCreatedAt = json['createdAt'] as String?;
    DateTime? createdAt;
    if (rawCreatedAt != null) {
      // "2026-11-12 14:36:00" -> treat as UTC
      final formatted = rawCreatedAt.replaceAll(' ', 'T');
      createdAt = DateTime.tryParse('${formatted}Z') ?? DateTime.tryParse(formatted);
    }

    final sno = json['sno'] as String? ?? '';
    final extRaw = json['extractedData'];

    Map<String, dynamic> ext = {};
    if (extRaw is String) {
      try {
        ext = jsonDecode(extRaw) as Map<String, dynamic>;
      } catch (_) {}
    } else if (extRaw is Map<String, dynamic>) {
      ext = extRaw;
    }

    const knownKeys = {
      'pvv', 'pvi', 'pvp', 'dcv', 'iv', 'ii', 'iHz', 'gv', 'gHz', 'it', 'ep',
      'tskWh', 'tkWh', 'irs', 'grs', 'pfs', 'd_type', 'rat', 'gov', 'guv',
      'gof', 'guf', 'ioc', 'dc', 'tmp', 'pvov', 'pvuv', 'pvoc', 'dcov', 'dcuv', 'ef'
    };

    final undocumented = <String, dynamic>{};
    ext.forEach((k, v) {
      if (!knownKeys.contains(k)) {
        undocumented[k] = v;
      }
    });

    return SmartnetLatestReading(
      createdAt: createdAt,
      sno: sno,
      pvv: parseDouble(ext['pvv']),
      pvi: parseDouble(ext['pvi']),
      pvp: parseDouble(ext['pvp']),
      dcv: parseDouble(ext['dcv']),
      iv: parseDouble(ext['iv']),
      ii: parseDouble(ext['ii']),
      iHz: parseDouble(ext['iHz']),
      gv: parseDouble(ext['gv']),
      gHz: parseDouble(ext['gHz']),
      it: parseDouble(ext['it']),
      ep: parseDouble(ext['ep']),
      tskWh: parseDouble(ext['tskWh']),
      tkWh: parseDouble(ext['tkWh']),
      irs: parseBool(ext['irs']),
      grs: parseBool(ext['grs']),
      pfs: parseBool(ext['pfs']),
      dType: ext['d_type'] as String?,
      rat: ext['rat'] as String?,
      gov: parseBool(ext['gov']),
      guv: parseBool(ext['guv']),
      gof: parseBool(ext['gof']),
      guf: parseBool(ext['guf']),
      ioc: parseBool(ext['ioc']),
      dc: parseBool(ext['dc']),
      tmp: parseBool(ext['tmp']),
      pvov: parseBool(ext['pvov']),
      pvuv: parseBool(ext['pvuv']),
      pvoc: parseBool(ext['pvoc']),
      dcov: parseBool(ext['dcov']),
      dcuv: parseBool(ext['dcuv']),
      ef: parseBool(ext['ef']),
      undocumentedFields: undocumented,
    );
  }
}

/// Point in today's graph response (`op=tg`).
class SmartnetTodayPoint {
  const SmartnetTodayPoint({
    required this.timestamp,
    required this.label,
    required this.pvp,
    required this.todayGen,
    required this.cumulativeGen,
  });

  final DateTime? timestamp;
  final String label;
  final double? pvp;
  final double? todayGen;
  final double? cumulativeGen;

  factory SmartnetTodayPoint.fromJson(Map<String, dynamic> json) {
    final rawTs = json['timestamp'] as String?;
    DateTime? ts;
    if (rawTs != null) {
      final formatted = rawTs.replaceAll(' ', 'T');
      ts = DateTime.tryParse('${formatted}Z') ?? DateTime.tryParse(formatted);
    }
    return SmartnetTodayPoint(
      timestamp: ts,
      label: json['label'] as String? ?? '',
      pvp: parseDouble(json['pvp']),
      todayGen: parseDouble(json['todayGen']),
      cumulativeGen: parseDouble(json['cumulativeGen']),
    );
  }
}

/// Graph response for today (`op=tg`).
class SmartnetTodayGraph {
  const SmartnetTodayGraph({
    required this.sno,
    required this.todayGen,
    required this.totalGen,
    required this.totalCuf,
    required this.lastPacketDate,
    required this.points,
  });

  final String sno;
  final double? todayGen;
  final double? totalGen;
  final double? totalCuf;
  final String? lastPacketDate;
  final List<SmartnetTodayPoint> points;

  factory SmartnetTodayGraph.fromJson(Map<String, dynamic> json) {
    final summary = json['summary'] as Map<String, dynamic>? ?? {};
    final rawData = json['data'] as List<dynamic>? ?? [];
    final points = rawData
        .whereType<Map<String, dynamic>>()
        .map((m) => SmartnetTodayPoint.fromJson(m))
        .toList();

    return SmartnetTodayGraph(
      sno: json['sno'] as String? ?? '',
      todayGen: parseDouble(summary['todayGen']),
      totalGen: parseDouble(summary['totalGen']),
      totalCuf: parseDouble(summary['totalCuf']),
      lastPacketDate: summary['lastPacketDate'] as String?,
      points: points,
    );
  }
}

/// Daily entry in 7 days history (`op=7d`).
class Smartnet7DaysPoint {
  const Smartnet7DaysPoint({
    required this.createdAt,
    required this.label,
    required this.dkWh,
    required this.tskWh,
  });

  final DateTime? createdAt;
  final String label;
  final double? dkWh;
  final double? tskWh;
}

class Smartnet7DaysHistory {
  const Smartnet7DaysHistory({required this.points});

  final List<Smartnet7DaysPoint> points;

  factory Smartnet7DaysHistory.fromJson(Map<String, dynamic> json) {
    final createdList = json['createdAt'] as List<dynamic>? ?? [];
    final dkWhList = json['dkWh'] as List<dynamic>? ?? [];
    final tskWhList = json['tskWh'] as List<dynamic>? ?? [];
    final labelsList = json['labels'] as List<dynamic>? ?? [];

    final points = <Smartnet7DaysPoint>[];
    final count = createdList.length;
    for (var i = 0; i < count; i++) {
      final rawCreatedAt = createdList[i] as String?;
      DateTime? dt;
      if (rawCreatedAt != null) {
        dt = DateTime.tryParse(rawCreatedAt);
      }
      final label = i < labelsList.length ? (labelsList[i] as String? ?? '') : '';
      final dkWh = i < dkWhList.length ? parseDouble(dkWhList[i]) : null;
      final tskWh = i < tskWhList.length ? parseDouble(tskWhList[i]) : null;

      points.add(Smartnet7DaysPoint(
        createdAt: dt,
        label: label,
        dkWh: dkWh,
        tskWh: tskWh,
      ));
    }

    return Smartnet7DaysHistory(points: points);
  }
}

/// Daily entry in monthly history (`op=mg`).
class SmartnetMonthPoint {
  const SmartnetMonthPoint({
    required this.createdAt,
    required this.label,
    required this.dkWh,
  });

  final DateTime? createdAt;
  final String label;
  final double? dkWh;
}

class SmartnetMonthHistory {
  const SmartnetMonthHistory({required this.points});

  final List<SmartnetMonthPoint> points;

  factory SmartnetMonthHistory.fromJson(Map<String, dynamic> json) {
    final createdList = json['createdAt'] as List<dynamic>? ?? [];
    final dkWhList = json['dkWh'] as List<dynamic>? ?? [];
    final labelsList = json['labels'] as List<dynamic>? ?? [];

    final points = <SmartnetMonthPoint>[];
    final count = createdList.length;
    for (var i = 0; i < count; i++) {
      final rawCreatedAt = createdList[i] as String?;
      DateTime? dt;
      if (rawCreatedAt != null) {
        dt = DateTime.tryParse(rawCreatedAt);
      }
      final label = i < labelsList.length ? (labelsList[i] as String? ?? '') : '';
      final dkWh = i < dkWhList.length ? parseDouble(dkWhList[i]) : null;

      points.add(SmartnetMonthPoint(
        createdAt: dt,
        label: label,
        dkWh: dkWh,
      ));
    }

    return SmartnetMonthHistory(points: points);
  }
}

/// Point in custom range telemetry log (`op=cr`).
class SmartnetCustomRangePoint {
  const SmartnetCustomRangePoint({
    required this.createdAt,
    this.pvv,
    this.pvp,
    this.gv,
    this.gHz,
    this.it,
    this.iv,
    this.ii,
    this.activeFaults = const [],
  });

  final DateTime? createdAt;
  final double? pvv;
  final double? pvp;
  final double? gv;
  final double? gHz;
  final double? it;
  final double? iv;
  final double? ii;
  final List<String> activeFaults;

  factory SmartnetCustomRangePoint.fromJson(Map<String, dynamic> json) {
    final rawCreatedAt = json['createdAt'] as String?;
    DateTime? dt;
    if (rawCreatedAt != null) {
      dt = DateTime.tryParse(rawCreatedAt);
    }

    final ext = json['extractedData'] as Map<String, dynamic>? ?? {};

    const faultKeys = ['gov', 'guv', 'gof', 'guf', 'ioc', 'dc', 'tmp', 'pvov', 'pvuv', 'pvoc', 'dcov', 'dcuv', 'ef'];
    final active = <String>[];
    for (final k in faultKeys) {
      if (parseBool(ext[k])) {
        active.add(k.toUpperCase());
      }
    }

    return SmartnetCustomRangePoint(
      createdAt: dt,
      pvv: parseDouble(ext['pvv']),
      pvp: parseDouble(ext['pvp']),
      gv: parseDouble(ext['gv']),
      gHz: parseDouble(ext['gHz']),
      it: parseDouble(ext['it']),
      iv: parseDouble(ext['iv']),
      ii: parseDouble(ext['ii']),
      activeFaults: active,
    );
  }
}
