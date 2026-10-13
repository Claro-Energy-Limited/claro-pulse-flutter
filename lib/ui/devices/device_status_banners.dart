import 'package:flutter/material.dart';

import '../../app/theme/claro_colors.dart';
import '../../app/theme/claro_dimens.dart';
import '../../app/theme/claro_type.dart';
import '../../core/api/models/device_models.dart';
import '../../core/util/relative_time.dart';
import '../components/claro_freshness_stamp.dart';

// Ported from the Kotlin `DeviceStatusCard.kt`: everything about a status that
// is NOT a "how much" number (is it running, is anything wrong, how fresh is
// this). Shared by Home and the detail screen.

bool isDeviceRunning(DeviceStatus? status) => status?.runStatus == 'RUNNING';

/// "Online — updated 2 min ago" and friends. Connection and run status are two
/// separate questions and are never collapsed into one.
String connectionLabel(DeviceStatus status, {DateTime? now}) {
  final last = status.lastReportedAt;
  switch (status.connectionStatus) {
    case 'ONLINE':
      return last == null ? 'Online' : 'Online — updated ${formatRelativeTime(last, now: now)}';
    case 'NEVER_REPORTED':
      return 'Never reported in yet';
    default:
      return last == null ? 'Offline' : 'Offline — last seen ${formatRelativeTime(last, now: now)}';
  }
}

class DeviceStatusBanners extends StatelessWidget {
  const DeviceStatusBanners({super.key, required this.status});

  final DeviceStatus status;

  @override
  Widget build(BuildContext context) {
    final faultText = status.faultText;
    final protections = status.protections;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _RunStatusBanner(runStatus: status.runStatus),
        if (faultText != null) ...[
          const SizedBox(height: ClaroSpacing.md),
          _AlertBanner(text: faultText, color: ClaroColors.fault, background: ClaroColors.faultBg),
        ],
        if (protections.dryRun || protections.waterLevelLow) ...[
          const SizedBox(height: ClaroSpacing.md),
          _AlertBanner(
            text: _protectionsText(protections),
            color: ClaroColors.warn,
            background: ClaroColors.warnBg,
          ),
        ],
        const SizedBox(height: ClaroSpacing.lg),
        ClaroFreshnessStamp(text: connectionLabel(status), isLive: status.connectionStatus == 'ONLINE'),
      ],
    );
  }

  static String _protectionsText(Protections p) {
    if (p.dryRun && p.waterLevelLow) return 'Dry-run and low water level protection active';
    if (p.dryRun) return 'Dry-run protection active — pump paused to avoid damage';
    return 'Low water level protection active';
  }
}

class _RunStatusBanner extends StatelessWidget {
  const _RunStatusBanner({required this.runStatus});

  final String runStatus;

  @override
  Widget build(BuildContext context) {
    final (label, dot) = switch (runStatus) {
      'RUNNING' => ('Pump running', ClaroColors.mint),
      'STOPPED' => ('Pump stopped', ClaroColors.onInkMuted),
      _ => ('Status unknown', ClaroColors.onInkMuted),
    };
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(ClaroSpacing.xl),
      decoration: BoxDecoration(
        color: ClaroColors.inkPanel,
        borderRadius: ClaroRadius.lg,
        border: Border.all(color: ClaroColors.borderDark),
      ),
      child: Row(
        children: [
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(shape: BoxShape.circle, color: dot),
          ),
          const SizedBox(width: ClaroSpacing.md),
          Text(label, style: ClaroType.title.copyWith(color: ClaroColors.onInk)),
        ],
      ),
    );
  }
}

/// The fault and protection banners: same shape, different colour.
class _AlertBanner extends StatelessWidget {
  const _AlertBanner({required this.text, required this.color, required this.background});

  final String text;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(ClaroSpacing.md),
      decoration: BoxDecoration(
        color: background.withValues(alpha: 0.14),
        borderRadius: ClaroRadius.md,
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning, size: 18, color: color),
          const SizedBox(width: ClaroSpacing.sm),
          Expanded(child: Text(text, style: ClaroType.body.copyWith(color: color))),
        ],
      ),
    );
  }
}
