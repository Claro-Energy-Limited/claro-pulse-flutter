import 'package:flutter/material.dart';

import '../../app/theme/claro_dimens.dart';
import '../../app/theme/claro_palette.dart';
import '../../app/theme/claro_type.dart';
import '../../core/api/models/device_models.dart';
import '../../core/api/models/pump_models.dart';
import '../../core/util/relative_time.dart';
import '../common/ui_kit.dart';
import '../components/dashed_path.dart';
import '../devices/device_kind.dart';
import 'home_cards.dart';
import 'pump_control.dart';
import 'pump_state.dart';

/// "Solar Pump" / "Solar Inverter": the friendly name shown in headers.
String deviceTitle(MyDevice device) =>
    DeviceKind.from(device.kind) == DeviceKind.inverter ? 'Solar Inverter' : 'Solar Pump';

/// The Home tab, built to be read at a glance, like a vehicle app.
///
/// The first screen answers the main questions without scrolling: is my pump
/// running, and how much water did it give today? The pump stands on a lit
/// "stage" with the key numbers on it, and the Start/Stop button sits right
/// below. Everything else (last run, today's numbers, suggestions) follows.
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
    required this.runs,
    required this.insights,
    required this.complaintUpdate,
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
    required this.onOpenComplaints,
    required this.onSeeAllRuns,
    required this.onOpenRunStory,
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

  /// Newest first; null or empty hides the run card.
  final List<PumpRun>? runs;

  /// Null hides the ring and the suggestion cards that depend on it.
  final PumpInsights? insights;

  /// The newest complaint with an update from the service team, if any.
  final Complaint? complaintUpdate;
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
  final VoidCallback onOpenComplaints;
  final VoidCallback onSeeAllRuns;
  final ValueChanged<PumpRun> onOpenRunStory;
  final VoidCallback onStart;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        color: p.accentText,
        backgroundColor: p.panel,
        onRefresh: onRefresh,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(ClaroSpacing.xl, ClaroSpacing.lg, ClaroSpacing.xl, kNavClearance),
          children: [
            _Header(
              device: device,
              unreadAlerts: unreadAlerts,
              bluetooth: bluetooth,
              onSwitchDevice: onSwitchDevice,
              onOpenAlerts: onOpenAlerts,
              onOpenBluetooth: onOpenBluetooth,
            ),
            const SizedBox(height: ClaroSpacing.lg),
            ..._body(context),
          ],
        ),
      ),
    );
  }

  List<Widget> _body(BuildContext context) {
    final p = context.palette;
    final devices = this.devices;
    if (devices == null && devicesError == null) {
      return [SizedBox(height: 360, child: Center(child: CircularProgressIndicator(color: p.accentText)))];
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
          TintedPanel(
            tint: p.warn,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Pending review', style: ClaroType.subtitle.copyWith(color: p.warnText)),
                const SizedBox(height: ClaroSpacing.xs),
                Text(
                  "Device ${pending.deviceIdentifier} is waiting for approval. You'll see it here once it's approved.",
                  style: ClaroType.body.copyWith(color: p.text),
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
    if (kind == DeviceKind.inverter) {
      return [
        _HeroStage(
          kind: kind,
          visual: visual,
          onTap: onOpenDetails,
          overlay: const _InverterOverlay(),
        ),
      ];
    }
    return _pumpBody(context);
  }

  List<Widget> _pumpBody(BuildContext context) {
    final status = this.status;
    final insights = this.insights;
    final lastRun = (runs == null || runs!.isEmpty) ? null : runs!.first;

    final hero = _HeroStage(
      kind: DeviceKind.pump,
      visual: visual,
      onTap: onOpenDetails,
      overlay: status == null && statusError != null
          ? null
          : _PumpOverlay(status: status, visual: visual, typicalDayLiters: insights?.typicalDayLiters),
    );

    if (status == null && statusError != null) {
      return [
        hero,
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

    final cards = _contextCards(context);
    return [
      hero,
      const SizedBox(height: ClaroSpacing.lg),
      PumpControlButton(visual: visual, onStart: onStart, onStop: onStop),
      if (status != null && needsAttention(status)) ...[
        const SizedBox(height: ClaroSpacing.lg),
        _AttentionCard(status: status),
      ],
      if (lastRun != null) ...[
        const SizedBox(height: ClaroSpacing.xl),
        LastRunCard(run: lastRun, onSeeAll: onSeeAllRuns, onOpenStory: () => onOpenRunStory(lastRun)),
      ],
      const SizedBox(height: ClaroSpacing.xl),
      const SectionHeader(title: 'Right now'),
      const SizedBox(height: ClaroSpacing.md),
      StatsStrip(items: [
        StripStat(
          icon: Icons.wb_sunny_rounded,
          value: formatOneDecimal(status?.live.solarPowerKw),
          unit: 'kW',
          label: 'Solar',
        ),
        StripStat(
          icon: Icons.schedule_rounded,
          value: formatOneDecimal(status?.today.runHours),
          unit: 'hrs',
          label: 'Run today',
        ),
        StripStat(
          icon: Icons.bolt_rounded,
          value: formatOneDecimal(status?.today.energyKwh),
          unit: 'kWh',
          label: 'Energy today',
        ),
        StripStat(
          icon: Icons.speed_rounded,
          value: formatWhole(status?.live.motorSpeedRpm),
          unit: 'RPM',
          label: 'Speed',
        ),
      ]),
      if (cards.isNotEmpty) ...[
        const SizedBox(height: ClaroSpacing.xl),
        const SectionHeader(title: 'For you'),
        const SizedBox(height: ClaroSpacing.md),
        ContextCarousel(cards: cards),
      ],
    ];
  }

  /// Most useful first: something to do, then something to know.
  List<ContextCardData> _contextCards(BuildContext context) {
    final i = insights;
    final update = complaintUpdate;
    return [
      if (i != null && i.panelsNeedCleaning)
        ContextCardData(
          icon: Icons.cleaning_services_rounded,
          title: 'Clean your solar panels',
          body: _cleaningText(i),
          tone: ContextTone.warning,
        ),
      if (update != null)
        ContextCardData(
          icon: Icons.support_agent_rounded,
          title: 'Complaint ${update.ticketNo} updated',
          body: update.latestUpdate ?? update.status.label,
          onTap: onOpenComplaints,
        ),
      if (i != null) ...[
        ContextCardData(
          icon: weatherIcon(i.tomorrowCondition),
          title: 'Tomorrow: ${i.tomorrowCondition.label.toLowerCase()}, ${i.tomorrowTempC}°C',
          body: 'About ${formatWhole(i.tomorrowExpectedLiters)} litres expected. '
              'Best time to run today: ${i.bestHours}.',
        ),
        ContextCardData(
          icon: Icons.savings_rounded,
          title: '₹${formatWhole(i.savingsThisMonthRupees)} saved this month',
          body: '₹${formatWhole(i.savingsTotalRupees)} since installation, compared with diesel.',
          tone: ContextTone.positive,
        ),
      ],
    ];
  }

  String _cleaningText(PumpInsights i) {
    final cleaned = DateTime.tryParse(i.lastCleanedOn);
    final days = cleaned == null ? null : DateTime.now().difference(cleaned).inDays;
    final last = days == null || days <= 0 ? '' : ' Last cleaned $days day${days == 1 ? '' : 's'} ago.';
    return 'Less water than expected for this much sun, usually from dust.$last';
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
    final p = context.palette;
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
                Text(greeting(), style: ClaroType.caption.copyWith(color: p.textMuted)),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        device == null ? 'Claro Pulse' : deviceTitle(device),
                        overflow: TextOverflow.ellipsis,
                        style: ClaroType.title.copyWith(color: p.text),
                      ),
                    ),
                    if (device != null) Icon(Icons.expand_more_rounded, color: p.textMuted, size: 22),
                  ],
                ),
                if (device != null) Text(device.deviceUid, style: ClaroType.caption.copyWith(color: p.accentText)),
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

/// The pump on a lit stage: a soft spotlight, a floor shadow, flowing-water
/// lines while it runs, and the key numbers laid over the bottom.
/// Tapping it opens the device details.
class _HeroStage extends StatefulWidget {
  const _HeroStage({required this.kind, required this.visual, required this.onTap, required this.overlay});

  final DeviceKind kind;
  final PumpVisual visual;
  final VoidCallback onTap;
  final Widget? overlay;

  @override
  State<_HeroStage> createState() => _HeroStageState();
}

class _HeroStageState extends State<_HeroStage> with SingleTickerProviderStateMixin {
  late final AnimationController _flow = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  bool get _live => widget.visual.isLive;

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(_HeroStage old) {
    super.didUpdateWidget(old);
    _sync();
  }

  void _sync() {
    if (_live) {
      if (!_flow.isAnimating) _flow.repeat();
    } else {
      _flow
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _flow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final isInverter = widget.kind == DeviceKind.inverter;
    final spot = p.isDark ? const Color(0x1AFFFFFF) : const Color(0xFFFFFFFF);
    final shade = p.isDark ? const Color(0xFF000000) : const Color(0xFF111110);

    return Semantics(
      button: true,
      label: isInverter ? 'Inverter details' : 'Pump details',
      child: GestureDetector(
        key: const ValueKey('device-hero'),
        onTap: widget.onTap,
        child: ClipRRect(
          borderRadius: const BorderRadius.all(Radius.circular(28)),
          child: Container(
            height: isInverter ? 300 : 420,
            decoration: BoxDecoration(
              color: p.panel,
              border: Border.all(color: p.border),
              borderRadius: const BorderRadius.all(Radius.circular(28)),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Spotlight from above.
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(0, -0.6),
                      radius: 0.9,
                      colors: [spot, spot.withValues(alpha: 0)],
                    ),
                  ),
                ),
                // Accent glow, only while running.
                AnimatedOpacity(
                  duration: ClaroMotion.slow,
                  opacity: _live ? 1 : 0,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: const Alignment(0, -0.15),
                        radius: 0.75,
                        colors: [p.accent.withValues(alpha: p.isDark ? 0.24 : 0.34), p.accent.withValues(alpha: 0)],
                      ),
                    ),
                  ),
                ),
                if (isInverter)
                  Image.asset('assets/images/device_hero_inverter.png', fit: BoxFit.cover)
                else ...[
                  // Floor shadow under the pump.
                  Align(
                    alignment: const Alignment(0, 0.18),
                    child: Container(
                      width: 200,
                      height: 22,
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.all(Radius.elliptical(100, 11)),
                        gradient: RadialGradient(
                          colors: [shade.withValues(alpha: p.isDark ? 0.55 : 0.18), shade.withValues(alpha: 0)],
                        ),
                      ),
                    ),
                  ),
                  // Flowing water while running.
                  if (_live)
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 200,
                      height: 40,
                      child: AnimatedBuilder(
                        animation: _flow,
                        builder: (context, _) => CustomPaint(painter: _FlowPainter(_flow.value, p.accentText)),
                      ),
                    ),
                  Positioned(
                    left: ClaroSpacing.xl,
                    right: ClaroSpacing.xl,
                    top: 44,
                    height: 190,
                    child: Image.asset('assets/images/device_hero_pump.png', fit: BoxFit.contain),
                  ),
                ],
                // Readable base for the numbers.
                if (widget.overlay != null)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: 190,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [p.panel.withValues(alpha: 0), p.panel.withValues(alpha: 0.96)],
                        ),
                      ),
                    ),
                  ),
                if (widget.overlay != null)
                  Positioned(
                    left: ClaroSpacing.lg,
                    right: ClaroSpacing.lg,
                    bottom: ClaroSpacing.lg,
                    child: widget.overlay!,
                  ),
                Positioned(
                  top: ClaroSpacing.md,
                  left: ClaroSpacing.md,
                  child: StatusChip(label: widget.visual.label, color: widget.visual.colorIn(p), pulse: _live),
                ),
                Positioned(
                  top: ClaroSpacing.md,
                  right: ClaroSpacing.md,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: ClaroSpacing.sm, vertical: 4),
                    decoration: BoxDecoration(
                      color: p.panel.withValues(alpha: 0.85),
                      borderRadius: ClaroRadius.pill,
                      border: Border.all(color: p.border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Details', style: ClaroType.caption.copyWith(color: p.text)),
                        Icon(Icons.chevron_right_rounded, size: 16, color: p.textMuted),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Three gently curved lines of moving dashes under the pump: water flowing.
class _FlowPainter extends CustomPainter {
  _FlowPainter(this.t, this.color);

  final double t;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    for (var i = 0; i < 3; i++) {
      final y = size.height * (0.25 + i * 0.25);
      final path = Path()
        ..moveTo(w * 0.12, y)
        ..quadraticBezierTo(w * 0.5, y + (i - 1) * 6, w * 0.88, y);
      final paint = Paint()
        ..color = color.withValues(alpha: 0.55 - i * 0.12)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round;
      drawDashedPath(canvas, path, paint, dash: 10, gap: 8, phase: -t * 36 - i * 6);
    }
  }

  @override
  bool shouldRepaint(_FlowPainter old) => old.t != t || old.color != color;
}

/// The numbers on the pump's stage: water today (counting up), how it's
/// flowing, and a ring against a typical day.
class _PumpOverlay extends StatelessWidget {
  const _PumpOverlay({required this.status, required this.visual, required this.typicalDayLiters});

  final DeviceStatus? status;
  final PumpVisual visual;
  final double? typicalDayLiters;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final status = this.status;
    final water = status?.today.waterLiters;
    final flow = status?.live.flowRateLpm;
    final typical = typicalDayLiters;

    final String detail = switch (visual) {
      PumpVisual.running =>
        flow != null && flow > 0 ? 'Flowing at ${formatWhole(flow)} L/min' : 'Pump is running',
      PumpVisual.starting || PumpVisual.stopping => 'Waiting for the pump to confirm…',
      PumpVisual.stopped => 'Pump is off',
      PumpVisual.offline => 'Pump is offline',
      PumpVisual.attention => 'Pump needs attention',
      _ => visual.label,
    };
    final updated = status?.lastReportedAt;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Water pumped today', style: ClaroType.label.copyWith(color: p.textMuted)),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Flexible(
                    child: CountUpText(
                      value: water,
                      format: formatWhole,
                      style: ClaroType.readoutXl.copyWith(color: p.text),
                    ),
                  ),
                  const SizedBox(width: ClaroSpacing.sm),
                  Text('litres', style: ClaroType.subtitle.copyWith(color: p.textMuted)),
                ],
              ),
              Text(
                detail,
                style: ClaroType.body.copyWith(color: visual.isLive ? p.accentText : p.textMuted),
              ),
              if (updated != null)
                Text('Updated ${formatRelativeTime(updated)}', style: ClaroType.caption.copyWith(color: p.textMuted)),
            ],
          ),
        ),
        if (typical != null && typical > 0 && water != null) ...[
          const SizedBox(width: ClaroSpacing.md),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ProgressRing(fraction: water / typical, label: '${(water / typical * 100).clamp(0, 999).round()}%'),
              const SizedBox(height: 4),
              Text('of a good day', style: ClaroType.caption.copyWith(color: p.textMuted, fontSize: 10)),
            ],
          ),
        ],
      ],
    );
  }
}

class _InverterOverlay extends StatelessWidget {
  const _InverterOverlay();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Solar inverter', style: ClaroType.subtitle.copyWith(color: p.text, fontWeight: FontWeight.w600)),
        Text(
          'Live readings for inverters are coming soon. Your inverter is connected and reporting.',
          style: ClaroType.caption.copyWith(color: p.textMuted),
        ),
      ],
    );
  }
}

class _AttentionCard extends StatelessWidget {
  const _AttentionCard({required this.status});

  final DeviceStatus status;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final pr = status.protections;
    final message = status.faultText ??
        (pr.dryRun
            ? 'Pump paused to protect itself: the well may be running dry.'
            : 'Water level is low. The pump will restart when it recovers.');
    return TintedPanel(
      tint: p.fault,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, color: p.faultText),
          const SizedBox(width: ClaroSpacing.md),
          Expanded(child: Text(message, style: ClaroType.body.copyWith(color: p.text))),
        ],
      ),
    );
  }
}
