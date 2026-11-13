import '../models/smartnet_models.dart';

enum InverterStateKind {
  healthy,
  warning,
  fault,
  resting,
  noData,
}

class InverterIssue {
  const InverterIssue({
    required this.id,
    required this.title,
    required this.where,
    required this.tag,
    required this.whatToDo,
    this.isFault = false,
  });

  final String id;
  final String title;
  final String where;
  final String tag;
  final String whatToDo;
  final bool isFault;
}

class InverterClassification {
  const InverterClassification({
    required this.kind,
    required this.label,
    required this.issues,
    required this.tryTheseFirst,
  });

  final InverterStateKind kind;
  final String label;
  final List<InverterIssue> issues;
  final List<String> tryTheseFirst;

  bool get isFault => kind == InverterStateKind.fault;
  bool get isWarning => kind == InverterStateKind.warning;
  bool get isHealthy => kind == InverterStateKind.healthy;
  bool get isResting => kind == InverterStateKind.resting;
  bool get isNoData => kind == InverterStateKind.noData;
}

abstract final class InverterClassifier {
  /// Evaluates the inverter state from the latest telemetry reading.
  static InverterClassification classify(SmartnetLatestReading? reading, {DateTime? nowUtc}) {
    if (reading == null) {
      return const InverterClassification(
        kind: InverterStateKind.noData,
        label: 'No data',
        issues: [],
        tryTheseFirst: [],
      );
    }

    final now = (nowUtc ?? DateTime.now()).toUtc();
    // IST time = UTC + 5:30
    final ist = now.add(const Duration(hours: 5, minutes: 30));
    final hourDecimal = ist.hour + (ist.minute / 60.0);
    // Daylight = 06:00 to 18:30 IST
    final isDaylight = hourDecimal >= 6.0 && hourDecimal <= 18.5;

    final issues = <InverterIssue>[];

    // Check fault flags
    if (reading.gov || reading.guv) {
      issues.add(const InverterIssue(
        id: 'grid_voltage',
        title: 'Grid voltage out of range',
        where: 'AC cable from the inverter through the ACDB to the grid',
        tag: 'May clear with a restart',
        whatToDo: 'Usually a grid-side issue; check the ACDB breaker; report if it repeats daily.',
        isFault: true,
      ));
    }
    if (reading.ef) {
      issues.add(const InverterIssue(
        id: 'ef',
        title: 'Earth fault',
        where: 'Grounding and cable connections',
        tag: 'Needs a technician',
        whatToDo: "Don't restart repeatedly; call a technician to check grounding.",
        isFault: true,
      ));
    }
    if (reading.ioc) {
      issues.add(const InverterIssue(
        id: 'ioc',
        title: 'Inverter over-current',
        where: 'Inverter power electronics',
        tag: 'Needs a technician',
        whatToDo: 'Power down the inverter and contact site service.',
        isFault: true,
      ));
    }
    if (reading.dc || reading.dcov || reading.dcuv) {
      issues.add(const InverterIssue(
        id: 'dc_bus',
        title: 'DC bus voltage out of range',
        where: 'DC bus / internal power stage',
        tag: 'Needs a technician',
        whatToDo: 'Check DCDB switch and DC array wiring.',
        isFault: true,
      ));
    }
    if (reading.tmp) {
      issues.add(const InverterIssue(
        id: 'tmp',
        title: 'Inverter temperature fault',
        where: 'Inverter heatsink / cooling vents',
        tag: 'Needs attention',
        whatToDo: "Check vents aren't blocked and the inverter isn't in direct sun.",
        isFault: true,
      ));
    }
    if (reading.pvov || reading.pvuv || reading.pvoc) {
      issues.add(const InverterIssue(
        id: 'pv_electrical',
        title: 'PV array electrical issue',
        where: 'DC array cables & junction box',
        tag: 'Needs a technician',
        whatToDo: 'Inspect solar panels and DC cabling for damage or disconnection.',
        isFault: true,
      ));
    }

    final hasFault = issues.any((i) => i.isFault);

    // Check warning conditions
    if (!hasFault) {
      if (reading.gof || reading.guf) {
        issues.add(const InverterIssue(
          id: 'grid_freq',
          title: 'Grid frequency unstable',
          where: 'Grid connection',
          tag: 'Usually clears on its own',
          whatToDo: 'No action needed unless it repeats often.',
          isFault: false,
        ));
      }

      final temp = reading.it;
      if (temp != null && temp >= 65.0) {
        issues.add(const InverterIssue(
          id: 'high_temp',
          title: 'Inverter too hot',
          where: 'Inverter heatsink / cooling vents',
          tag: 'Needs attention',
          whatToDo: "Check vents aren't blocked and the inverter isn't in direct sun.",
          isFault: false,
        ));
      }

      // Stale data check in daylight (> 45 minutes)
      if (isDaylight && reading.createdAt != null) {
        final age = now.difference(reading.createdAt!.toUtc());
        if (age.inMinutes > 45) {
          issues.add(const InverterIssue(
            id: 'stale_data',
            title: 'Monitoring link lost',
            where: 'Black 4G dongle under the inverter',
            tag: 'Site staff can check this',
            whatToDo: 'Check the dongle is plugged in and lit, the SIM, and mobile signal.',
            isFault: false,
          ));
        }
      }
    }

    // Determine state
    if (hasFault) {
      final tryFirst = _buildTryFirst(efActive: reading.ef);
      final count = issues.where((i) => i.isFault).length;
      return InverterClassification(
        kind: InverterStateKind.fault,
        label: count == 1 ? '1 fault' : '$count faults',
        issues: issues,
        tryTheseFirst: tryFirst,
      );
    }

    if (issues.isNotEmpty) {
      final tryFirst = _buildTryFirst(efActive: reading.ef);
      return InverterClassification(
        kind: InverterStateKind.warning,
        label: 'Needs watching',
        issues: issues,
        tryTheseFirst: tryFirst,
      );
    }

    // Resting check (outside daylight & low PV power)
    final pvp = reading.pvp ?? 0.0;
    if (!isDaylight && pvp < 20.0) {
      return const InverterClassification(
        kind: InverterStateKind.resting,
        label: 'Resting, no sun',
        issues: [],
        tryTheseFirst: [],
      );
    }

    return const InverterClassification(
      kind: InverterStateKind.healthy,
      label: 'Working well',
      issues: [],
      tryTheseFirst: [],
    );
  }

  static List<String> _buildTryFirst({required bool efActive}) {
    final list = <String>[];
    if (!efActive) {
      list.add('Restart: switch off the ACDB breaker, then the DC switch in the DCDB; wait 1 minute; switch DC on first, then AC.');
    }
    list.add('Check both breakers (DCDB left box, ACDB right box) are ON.');
    list.add('Check the 4G dongle under the inverter is plugged in and lit.');
    list.add('Clean the panels with plain water, early morning (no detergent or scrubbing).');
    return list;
  }
}
