// Data for features the backend does not provide yet: pump details, complaints,
// notifications and start/stop. Today only the mock API fills these in; the
// real API reports them as "not available yet" until the server supports them.

/// Static facts about an installed pump or inverter.
class PumpDetails {
  const PumpDetails({
    required this.deviceId,
    required this.model,
    required this.capacity,
    required this.imei,
    required this.serialNo,
    required this.installedOn,
    required this.siteAddress,
    required this.installedBy,
    required this.warrantyUntil,
    required this.controller,
    required this.panels,
  });

  final String deviceId;

  /// e.g. "Claro SP-5 Solar Surface Pump".
  final String model;

  /// e.g. "5 HP".
  final String capacity;
  final String imei;
  final String? serialNo;

  /// ISO date, e.g. "2026-03-14".
  final String installedOn;
  final String siteAddress;
  final String installedBy;

  /// ISO date.
  final String warrantyUntil;

  /// The controller fitted to the pump, e.g. "STACON VFD 5.5 kW".
  final String controller;

  /// The solar array, e.g. "12 × 335 W panels".
  final String panels;
}

enum ComplaintStatus {
  open('Open'),
  inProgress('In progress'),
  resolved('Resolved');

  const ComplaintStatus(this.label);
  final String label;
}

/// The problem types a farmer can pick when raising a complaint.
enum ComplaintCategory {
  pumpNotStarting('Pump not starting'),
  lowWaterFlow('Low water flow'),
  solarPanel('Solar panel problem'),
  deviceOffline('Device offline'),
  noise('Unusual noise'),
  other('Something else');

  const ComplaintCategory(this.label);
  final String label;
}

class Complaint {
  const Complaint({
    required this.id,
    required this.ticketNo,
    required this.deviceId,
    required this.category,
    required this.description,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.latestUpdate,
  });

  final String id;

  /// Shown to the farmer, e.g. "CP-1042".
  final String ticketNo;
  final String deviceId;
  final ComplaintCategory category;
  final String description;
  final ComplaintStatus status;

  /// ISO timestamps.
  final String createdAt;
  final String updatedAt;

  /// The newest note from the service team, if any.
  final String? latestUpdate;
}

enum NotificationKind { fault, offline, info, success }

class AppNotification {
  const AppNotification({
    required this.id,
    required this.kind,
    required this.title,
    required this.body,
    required this.createdAt,
    this.read = false,
  });

  final String id;
  final NotificationKind kind;
  final String title;
  final String body;

  /// ISO timestamp.
  final String createdAt;
  final bool read;
}

enum PumpCommand { start, stop }

/// One pump run: from when it started until it stopped. [endedAt] is null
/// while the pump is still running, and the totals are "so far".
class PumpRun {
  const PumpRun({
    required this.startedAt,
    required this.endedAt,
    required this.waterLiters,
    required this.energyKwh,
    required this.avgFlowLpm,
  });

  /// ISO timestamps.
  final String startedAt;
  final String? endedAt;
  final double waterLiters;
  final double energyKwh;
  final double avgFlowLpm;

  bool get isOngoing => endedAt == null;

  /// Length of the run; for an ongoing run, up to [now].
  Duration duration([DateTime? now]) {
    final start = DateTime.tryParse(startedAt);
    if (start == null) return Duration.zero;
    final end = endedAt == null ? (now ?? DateTime.now()) : DateTime.tryParse(endedAt!) ?? start;
    final d = end.toUtc().difference(start.toUtc());
    return d.isNegative ? Duration.zero : d;
  }
}

enum WeatherCondition {
  sunny('Sunny'),
  partlyCloudy('Partly cloudy'),
  cloudy('Cloudy'),
  rain('Rain');

  const WeatherCondition(this.label);
  final String label;
}

/// Helpful extras for the Home screen, computed from the pump's data and the
/// weather at the site.
class PumpInsights {
  const PumpInsights({
    required this.todayCondition,
    required this.todayTempC,
    required this.bestHours,
    required this.tomorrowCondition,
    required this.tomorrowTempC,
    required this.tomorrowExpectedLiters,
    required this.savingsThisMonthRupees,
    required this.savingsTotalRupees,
    required this.dieselSavedLiters,
    required this.panelsNeedCleaning,
    required this.lastCleanedOn,
  });

  final WeatherCondition todayCondition;
  final int todayTempC;

  /// The strongest-sun window today, e.g. "10 AM – 3 PM".
  final String bestHours;
  final WeatherCondition tomorrowCondition;
  final int tomorrowTempC;
  final double tomorrowExpectedLiters;

  /// Compared with running a diesel pump for the same water.
  final double savingsThisMonthRupees;
  final double savingsTotalRupees;
  final double dieselSavedLiters;

  /// True when output is lower than expected for the sunshine, which usually
  /// means dusty panels.
  final bool panelsNeedCleaning;

  /// ISO date.
  final String lastCleanedOn;
}

/// One month's summary, for the monthly report screen.
class MonthlyReport {
  const MonthlyReport({
    required this.month,
    required this.waterLiters,
    required this.runHours,
    required this.energyKwh,
    required this.daysRun,
    required this.bestDay,
    required this.bestDayLiters,
    required this.savingsRupees,
    required this.dailyWaterLiters,
  });

  /// First day of the month, ISO date.
  final String month;
  final double waterLiters;
  final double runHours;
  final double energyKwh;
  final int daysRun;

  /// ISO date of the day with the most water.
  final String bestDay;
  final double bestDayLiters;
  final double savingsRupees;

  /// One value per day of the month so far; null = no report that day.
  final List<double?> dailyWaterLiters;
}
