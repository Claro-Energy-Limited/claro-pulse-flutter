import 'package:flutter/material.dart';

import '../../app/theme/claro_colors.dart';
import '../../app/theme/claro_dimens.dart';
import '../../app/theme/claro_type.dart';
import '../../core/api/models/device_models.dart';
import '../components/claro_primary_button.dart';
import '../components/device_hero_card.dart';
import '../devices/device_kind.dart';
import '../devices/device_metrics.dart';
import '../devices/device_status_banners.dart';
import '../icons/claro_icons.dart';
import '../weather/weather_widget.dart';
import 'device_pager.dart';

/// Height of the loading and error boxes. The Home tab scrolls, so these
/// states can't fill the viewport; a fixed box keeps them from sitting
/// cramped at the top. Matches a device page's loading box.
const double _stateBoxHeight = 280;

/// The Home tab, ported from the Kotlin `HomeTabContent`.
///
/// Shows exactly ONE state, chosen in order: loading, error, pending claim,
/// empty, device pager. A slow network must never look like owning nothing,
/// and a farmer who has already scanned a device must see that it's pending,
/// not an empty screen again. `HomeScreen` owns every request; this widget
/// only renders what it is given.
class HomeTab extends StatelessWidget {
  const HomeTab({
    super.key,
    required this.devices,
    required this.devicesError,
    required this.claims,
    required this.statusById,
    required this.statusErrorById,
    required this.onRetryDevices,
    required this.onPageSettled,
    required this.onRetryStatus,
    required this.onAddDevice,
  });

  final List<MyDevice>? devices;
  final String? devicesError;
  final List<DeviceClaim>? claims;
  final Map<String, DeviceStatus> statusById;
  final Map<String, String> statusErrorById;
  final VoidCallback onRetryDevices;
  final ValueChanged<int> onPageSettled;
  final ValueChanged<String> onRetryStatus;
  final VoidCallback onAddDevice;

  @override
  Widget build(BuildContext context) {
    final devices = this.devices;
    final devicesError = this.devicesError;

    if (devices == null && devicesError == null) {
      return const _Spinner();
    }
    if (devices == null) {
      return _ErrorState(message: devicesError!, onRetry: onRetryDevices);
    }
    if (devices.isEmpty) {
      final pending = claims?.where((c) => c.status == 'PENDING').firstOrNull;
      return pending != null ? _PendingClaimState(claim: pending) : _EmptyState(onAddDevice: onAddDevice);
    }
    return DevicePager<MyDevice>(
      items: devices,
      onPageSettled: onPageSettled,
      pageBuilder: (device) => _DevicePage(
        device: device,
        status: statusById[device.deviceId],
        error: statusErrorById[device.deviceId],
        onRetry: () => onRetryStatus(device.deviceId),
      ),
    );
  }
}

class _DevicePage extends StatelessWidget {
  const _DevicePage({required this.device, required this.status, required this.error, required this.onRetry});

  final MyDevice device;
  final DeviceStatus? status;
  final String? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final status = this.status;
    final error = this.error;
    final kind = DeviceKind.from(device.kind);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(device.deviceUid, style: ClaroType.subtitle.copyWith(color: ClaroColors.onInkMuted)),
        const SizedBox(height: ClaroSpacing.md),
        if (status != null) ...[
          DeviceHeroCard(
            kind: kind,
            isRunning: isDeviceRunning(status),
            callouts: heroCalloutsFor(kind, status),
            todaySummary: heroTodaySummaryFor(kind, status),
            comingSoon: kind == DeviceKind.inverter,
          ),
          const SizedBox(height: ClaroSpacing.lg),
          DeviceStatusBanners(status: status),
        ] else if (error != null)
          _ErrorState(message: error, onRetry: onRetry)
        else
          const _Spinner(),
      ],
    );
  }
}

class _Spinner extends StatelessWidget {
  const _Spinner();

  @override
  Widget build(BuildContext context) => const SizedBox(
        height: _stateBoxHeight,
        child: Center(child: CircularProgressIndicator(color: ClaroColors.mint)),
      );
}

/// Used for the device list AND a single device's status.
class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: _stateBoxHeight),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Couldn't load your dashboard",
              style: ClaroType.title.copyWith(color: ClaroColors.onInk),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: ClaroSpacing.xs),
            Text(message, style: ClaroType.body.copyWith(color: ClaroColors.onInkMuted), textAlign: TextAlign.center),
            const SizedBox(height: ClaroSpacing.lg),
            ClaroPrimaryButton(text: 'Try again', onPressed: onRetry),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAddDevice});

  final VoidCallback onAddDevice;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const WeatherWidget(snapshot: WeatherSnapshot.sample),
        const SizedBox(height: ClaroSpacing.xl),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(ClaroSpacing.xl),
          decoration: BoxDecoration(
            color: ClaroColors.inkPanel,
            borderRadius: ClaroRadius.lg,
            border: Border.all(color: ClaroColors.borderDark),
          ),
          child: Column(
            children: [
              const NavHomeIcon(size: 40, color: ClaroColors.mint),
              const SizedBox(height: ClaroSpacing.md),
              Text('No devices yet', style: ClaroType.title.copyWith(color: ClaroColors.onInk)),
              const SizedBox(height: ClaroSpacing.xs),
              Text(
                'Scan the QR code on your device to add it to your account.',
                style: ClaroType.body.copyWith(color: ClaroColors.onInkMuted),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: ClaroSpacing.lg),
              ClaroPrimaryButton(text: 'Add device', onPressed: onAddDevice),
            ],
          ),
        ),
      ],
    );
  }
}

class _PendingClaimState extends StatelessWidget {
  const _PendingClaimState({required this.claim});

  final DeviceClaim claim;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(ClaroSpacing.xl),
          decoration: BoxDecoration(
            color: ClaroColors.warnBg.withValues(alpha: 0.14),
            borderRadius: ClaroRadius.lg,
            border: Border.all(color: ClaroColors.warn.withValues(alpha: 0.4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Pending review', style: ClaroType.title.copyWith(color: ClaroColors.warn)),
              const SizedBox(height: ClaroSpacing.xs),
              Text(
                "Device ${claim.deviceIdentifier} is waiting for your utility's team to approve it. "
                "You'll see its data here once that's done.",
                style: ClaroType.body.copyWith(color: ClaroColors.onInk),
              ),
            ],
          ),
        ),
        const SizedBox(height: ClaroSpacing.xl),
        const WeatherWidget(snapshot: WeatherSnapshot.sample),
      ],
    );
  }
}
