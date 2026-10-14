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
