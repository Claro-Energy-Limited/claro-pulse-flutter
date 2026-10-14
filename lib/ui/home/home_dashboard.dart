import 'package:flutter/material.dart';

import '../../app/theme/claro_colors.dart';
import '../../app/theme/claro_dimens.dart';
import '../../app/theme/claro_type.dart';
import '../../core/api/models/device_models.dart';
import '../../core/util/relative_time.dart';
import '../common/ui_kit.dart';
import '../devices/device_kind.dart';
import 'pump_control.dart';
import 'pump_state.dart';

/// "Solar Pump" / "Solar Inverter": the friendly name shown in headers.
String deviceTitle(MyDevice device) =>
    DeviceKind.from(device.kind) == DeviceKind.inverter ? 'Solar Inverter' : 'Solar Pump';

/// The Home tab: the farmer's pump front and centre, like a vehicle app shows
/// the vehicle. Everything here answers "is my pump working, and how much water
/// did I get today?" Technical readings live one tap away in Pump details.
class HomeDashboard extends StatelessWidget {
  const HomeDashboard({
    super.key,
    required this.devices,
    required this.devicesError,
    required this.claims,
    required this.device,
    required this.status,
    required this.statusError,
    required this.visual,
    required this.unreadAlerts,
    required this.bluetooth,
    required this.onRefresh,
    required this.onRetryDevices,
    required this.onRetryStatus,
    required this.onAddDevice,
    required this.onSwitchDevice,
    required this.onOpenDetails,
    required this.onOpenAlerts,
    required this.onOpenBluetooth,
    required this.onStart,
    required this.onStop,
  });

  final List<MyDevice>? devices;
  final String? devicesError;
  final List<DeviceClaim>? claims;
  final MyDevice? device;
  final DeviceStatus? status;
  final String? statusError;
  final PumpVisual visual;
  final int unreadAlerts;
  final ValueNotifier<BluetoothLink> bluetooth;
  final Future<void> Function() onRefresh;
  final VoidCallback onRetryDevices;
  final VoidCallback onRetryStatus;
  final VoidCallback onAddDevice;
  final VoidCallback onSwitchDevice;
  final VoidCallback onOpenDetails;
  final VoidCallback onOpenAlerts;
  final VoidCallback onOpenBluetooth;
  final VoidCallback onStart;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        color: ClaroColors.mint,
        backgroundColor: ClaroColors.inkPanel,
        onRefresh: onRefresh,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(ClaroSpacing.xl, ClaroSpacing.lg, ClaroSpacing.xl, ClaroSpacing.xxl),
          children: [
            _Header(
              device: device,
              unreadAlerts: unreadAlerts,
              bluetooth: bluetooth,
              onSwitchDevice: onSwitchDevice,
              onOpenAlerts: onOpenAlerts,
              onOpenBluetooth: onOpenBluetooth,
            ),
            const SizedBox(height: ClaroSpacing.xl),
            ..._body(context),
          ],
        ),
      ),
    );
  }

  List<Widget> _body(BuildContext context) {
    final devices = this.devices;
    if (devices == null && devicesError == null) {
      return const [
        SizedBox(height: 320, child: Center(child: CircularProgressIndicator(color: ClaroColors.mint))),
      ];
    }
    if (devices == null) {
      return [
        MessageState(
          icon: Icons.cloud_off_rounded,
          title: "Couldn't load your pumps",
          message: devicesError!,
          actionLabel: 'Try again',
          onAction: onRetryDevices,
          isError: true,
        ),
      ];
    }
    final device = this.device;
    if (devices.isEmpty || device == null) {
      final pending = claims?.where((c) => c.status == 'PENDING').firstOrNull;
      return [
        if (pending != null) ...[
          Panel(
            color: ClaroColors.warn.withValues(alpha: 0.10),
            borderColor: ClaroColors.warn.withValues(alpha: 0.4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Pending review', style: ClaroType.subtitle.copyWith(color: ClaroColors.warn)),
                const SizedBox(height: ClaroSpacing.xs),
                Text(
                  "Device ${pending.deviceIdentifier} is waiting for approval. You'll see it here once it's approved.",
                  style: ClaroType.body.copyWith(color: ClaroColors.onInk),
                ),
              ],
            ),
          ),
          const SizedBox(height: ClaroSpacing.lg),
        ],
        MessageState(
          icon: Icons.water_drop_outlined,
          title: 'No pump added yet',
          message: 'Scan the QR code on your pump to add it to your account.',
          actionLabel: 'Add a device',
          onAction: onAddDevice,
        ),
      ];
    }

    final kind = DeviceKind.from(device.kind);
    return [
      _Hero(kind: kind, visual: visual),
      const SizedBox(height: ClaroSpacing.xl),
      if (kind == DeviceKind.inverter)
        ..._inverterBody()
      else
        ..._pumpBody(context),
      const SizedBox(height: ClaroSpacing.lg),
      Panel(
        onTap: onOpenDetails,
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: context.panelHigh, borderRadius: ClaroRadius.md),
              child: Icon(Icons.info_outline_rounded, color: context.brandMint, size: 20),
            ),
            const SizedBox(width: ClaroSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    kind == DeviceKind.inverter ? 'Inverter details' : 'Pump details',
                    style: ClaroType.subtitle.copyWith(color: context.textPrimary),
                  ),
                  Text(
                    'Model, IMEI, installation and warranty',
                    style: ClaroType.caption.copyWith(color: context.textSecondary),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: context.textSecondary),
          ],
        ),
      ),
    ];
  }

  List<Widget> _inverterBody() => [
        Panel(
          child: Row(
            children: [
              const Icon(Icons.hourglass_top_rounded, color: ClaroColors.onInkMuted),
              const SizedBox(width: ClaroSpacing.md),
              Expanded(
                child: Text(
                  'Live readings for inverters are coming soon. Your inverter is connected and reporting.',
                  style: ClaroType.body.copyWith(color: ClaroColors.onInkMuted),
                ),
              ),
            ],
          ),
        ),
      ];

  List<Widget> _pumpBody(BuildContext context) {
    final status = this.status;
    if (status == null && statusError != null) {
      return [
        MessageState(
          icon: Icons.sync_problem_rounded,
          title: "Couldn't reach your pump",
          message: statusError!,
          actionLabel: 'Try again',
          onAction: onRetryStatus,
          isError: true,
        ),
      ];
    }

    final flow = status?.live.flowRateLpm;
    final String detail;
    switch (visual) {
      case PumpVisual.running:
        detail = flow != null && flow > 0 ? 'Flowing at ${formatWhole(flow)} litres a minute' : 'Pump is running';
      case PumpVisual.starting:
        detail = 'Waiting for the pump to confirm…';
      case PumpVisual.stopping:
        detail = 'Waiting for the pump to confirm…';
      case PumpVisual.stopped:
        detail = 'Pump is off';
      case PumpVisual.offline:
        detail = 'Pump is offline';
      case PumpVisual.attention:
        detail = 'Pump needs attention';
      default:
        detail = visual.label;
    }
    final updated = status?.lastReportedAt;

    return [
      Text('Water pumped today', style: ClaroType.label.copyWith(color: context.textSecondary)),
      const SizedBox(height: ClaroSpacing.xs),
      Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Flexible(
            child: Text(
              formatWhole(status?.today.waterLiters),
              overflow: TextOverflow.ellipsis,
              style: ClaroType.readoutXl.copyWith(color: context.textPrimary),
            ),
          ),
          const SizedBox(width: ClaroSpacing.sm),
          Text('litres', style: ClaroType.subtitle.copyWith(color: context.textSecondary)),
        ],
      ),
      const SizedBox(height: ClaroSpacing.xs),
      Text(
        detail,
        style: ClaroType.body.copyWith(
          color: visual == PumpVisual.running ? context.brandMint : context.textSecondary,
        ),
      ),
      if (updated != null)
        Text(
          'Updated ${formatRelativeTime(updated)}',
          style: ClaroType.caption.copyWith(color: context.textSecondary),
        ),
      const SizedBox(height: ClaroSpacing.lg),
      PumpControlButton(visual: visual, onStart: onStart, onStop: onStop),
      if (status != null && needsAttention(status)) ...[
        const SizedBox(height: ClaroSpacing.lg),
        _AttentionCard(status: status),
      ],
      const SizedBox(height: ClaroSpacing.xl),
      Row(
        children: [
          Expanded(
            child: StatTile(
              icon: Icons.wb_sunny_rounded,
              label: 'Solar power now',
              value: formatOneDecimal(status?.live.solarPowerKw),
              unit: 'kW',
            ),
          ),
          const SizedBox(width: ClaroSpacing.md),
          Expanded(
            child: StatTile(
              icon: Icons.schedule_rounded,
              label: 'Run time today',
              value: formatOneDecimal(status?.today.runHours),
              unit: 'hrs',
            ),
          ),
        ],
      ),
      const SizedBox(height: ClaroSpacing.md),
      Row(
        children: [
          Expanded(
            child: StatTile(
              icon: Icons.bolt_rounded,
              label: 'Energy used today',
              value: formatOneDecimal(status?.today.energyKwh),
              unit: 'kWh',
            ),
          ),
          const SizedBox(width: ClaroSpacing.md),
          Expanded(
            child: StatTile(
              icon: Icons.speed_rounded,
              label: 'Pump speed',
              value: formatWhole(status?.live.motorSpeedRpm),
              unit: 'RPM',
            ),
          ),
        ],
      ),
    ];
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.device,
    required this.unreadAlerts,
    required this.bluetooth,
    required this.onSwitchDevice,
    required this.onOpenAlerts,
    required this.onOpenBluetooth,
  });

  final MyDevice? device;
  final int unreadAlerts;
  final ValueNotifier<BluetoothLink> bluetooth;
  final VoidCallback onSwitchDevice;
  final VoidCallback onOpenAlerts;
  final VoidCallback onOpenBluetooth;

  @override
  Widget build(BuildContext context) {
    final device = this.device;
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: device == null ? null : onSwitchDevice,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(greeting(), style: ClaroType.caption.copyWith(color: context.textSecondary)),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        device == null ? 'Claro Pulse' : deviceTitle(device),
                        overflow: TextOverflow.ellipsis,
                        style: ClaroType.title.copyWith(color: context.textPrimary),
                      ),
                    ),
                    if (device != null)
                      Icon(Icons.expand_more_rounded, color: context.textSecondary, size: 22),
                  ],
                ),
                if (device != null)
                  Text(device.deviceUid, style: ClaroType.caption.copyWith(color: context.brandMint)),
              ],
            ),
          ),
        ),
        if (device != null && DeviceKind.from(device.kind) == DeviceKind.pump) ...[
          ValueListenableBuilder<BluetoothLink>(
            valueListenable: bluetooth,
            builder: (context, link, _) => CircleIconButton(
              icon: link == BluetoothLink.connected ? Icons.bluetooth_connected_rounded : Icons.bluetooth_rounded,
              tooltip: 'Bluetooth',
              active: link == BluetoothLink.connected,
              onPressed: onOpenBluetooth,
            ),
          ),
          const SizedBox(width: ClaroSpacing.sm),
        ],
        CircleIconButton(
          icon: Icons.notifications_none_rounded,
          tooltip: 'Alerts',
          badgeCount: unreadAlerts,
          onPressed: onOpenAlerts,
        ),
      ],
    );
  }
}

/// The device photo, with a soft mint glow behind it while the pump runs.
class _Hero extends StatelessWidget {
  const _Hero({required this.kind, required this.visual});

  final DeviceKind kind;
  final PumpVisual visual;

  @override
  Widget build(BuildContext context) {
    final glowing = visual.isLive;
    final isInverter = kind == DeviceKind.inverter;
    return ClipRRect(
      borderRadius: ClaroRadius.lg,
      child: AnimatedContainer(
        duration: ClaroMotion.slow,
        height: 260,
        decoration: BoxDecoration(
          gradient: RadialGradient(
            radius: 0.8,
            colors: glowing
                ? [ClaroColors.mint.withValues(alpha: 0.26), ClaroColors.mint.withValues(alpha: 0)]
                : [const Color(0x14FFFFFF), const Color(0x00FFFFFF)],
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (isInverter)
              Image.asset('assets/images/device_hero_inverter.png', fit: BoxFit.cover)
            else
              Padding(
                padding: const EdgeInsets.fromLTRB(ClaroSpacing.xl, ClaroSpacing.xxl, ClaroSpacing.xl, ClaroSpacing.md),
                child: Image.asset('assets/images/device_hero_pump.png', fit: BoxFit.contain),
              ),
            Positioned(
              top: ClaroSpacing.md,
              left: ClaroSpacing.md,
              child: StatusChip(label: visual.label, color: visual.color, pulse: visual.isLive),
            ),
          ],
        ),
      ),
    );
  }
}

class _AttentionCard extends StatelessWidget {
  const _AttentionCard({required this.status});

  final DeviceStatus status;

  @override
  Widget build(BuildContext context) {
    final p = status.protections;
    final message = status.faultText ??
        (p.dryRun
            ? 'Pump paused to protect itself: the well may be running dry.'
            : 'Water level is low. The pump will restart when it recovers.');
    return Panel(
      color: ClaroColors.fault.withValues(alpha: 0.10),
      borderColor: ClaroColors.fault.withValues(alpha: 0.4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, color: ClaroColors.fault),
          const SizedBox(width: ClaroSpacing.md),
          Expanded(child: Text(message, style: ClaroType.body.copyWith(color: ClaroColors.onInk))),
        ],
      ),
    );
  }
}
