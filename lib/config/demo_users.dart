/// Hardcoded demo users for SmartNet Geocon live inverter integration.
class DemoUserConfig {
  const DemoUserConfig({
    required this.phone,
    required this.name,
    required this.rmuSno,
    required this.inverterSerial,
    required this.rmuImei,
    required this.siteName,
    required this.districtState,
    required this.model,
    required this.ratingKva,
    required this.panelCapacityKwp,
    required this.installedDate,
  });

  final String phone;
  final String name;
  final String rmuSno; // Used as `sno` parameter for SmartNet API
  final String inverterSerial;
  final String rmuImei;
  final String siteName;
  final String districtState;
  final String model;
  final double ratingKva;
  final double panelCapacityKwp;
  final String installedDate;

  /// Clean 10-digit number without country code
  String get cleanPhone {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.length >= 10) {
      return digits.substring(digits.length - 10);
    }
    return digits;
  }
}

abstract final class DemoUsers {
  static const Map<String, DemoUserConfig> byPhone = {
    '9000000001': DemoUserConfig(
      phone: '9000000001',
      name: 'Ramesh',
      rmuSno: 'S2SEG1240027560',
      inverterSerial: '25L12324B0',
      rmuImei: '860212400275600',
      siteName: 'Jaipur Solar Park',
      districtState: 'Rangareddy, Telangana',
      model: 'GTI-1P · type SEG1',
      ratingKva: 2.0,
      panelCapacityKwp: 2.0,
      installedDate: '2026-10-10',
    ),
    '9000000002': DemoUserConfig(
      phone: '9000000002',
      name: 'Lakshmi',
      rmuSno: 'S2SEG1240027863',
      inverterSerial: '25L12757B0',
      rmuImei: '860212400278630',
      siteName: 'Jaipur Solar Park',
      districtState: 'Rangareddy, Telangana',
      model: 'GTI-1P · type SEG1',
      ratingKva: 2.0,
      panelCapacityKwp: 2.0,
      installedDate: '2026-10-10',
    ),
    '9000000003': DemoUserConfig(
      phone: '9000000003',
      name: 'Suresh',
      rmuSno: 'S2SEG1240027869',
      inverterSerial: '25L12790B0',
      rmuImei: '860212400278690',
      siteName: 'Jaipur Solar Park',
      districtState: 'Rangareddy, Telangana',
      model: 'GTI-1P · type SEG1',
      ratingKva: 2.0,
      panelCapacityKwp: 2.0,
      installedDate: '2026-10-10',
    ),
  };

  /// Returns true if [phone] matches one of the demo users.
  static bool isDemoUser(String? phone) {
    if (phone == null) return false;
    final clean = phone.replaceAll(RegExp(r'\D'), '');
    final last10 = clean.length >= 10 ? clean.substring(clean.length - 10) : clean;
    return byPhone.containsKey(last10);
  }

  /// Finds the DemoUserConfig for [phone], or null if not a demo user.
  static DemoUserConfig? findByPhone(String? phone) {
    if (phone == null) return null;
    final clean = phone.replaceAll(RegExp(r'\D'), '');
    final last10 = clean.length >= 10 ? clean.substring(clean.length - 10) : clean;
    return byPhone[last10];
  }
}
