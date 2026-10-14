import 'package:flutter/material.dart';

import '../../app/theme/claro_colors.dart';
import '../../app/theme/claro_dimens.dart';
import '../../app/theme/claro_type.dart';
import '../devices/device_kind.dart';
import 'dashed_path.dart';

/// One live reading annotated around the hero photo, e.g. Solar · 5.4 kW.
class HeroCallout {
  const HeroCallout({required this.label, required this.value, required this.unit});

  final String label;
  final String value;
  final String unit;
}

/// A "since midnight" total shown below the diagram: a plain tile, no wire.
class HeroMetric {
  const HeroMetric({required this.label, required this.value, required this.unit});

  final String label;
  final String value;
  final String unit;
}

/// The app's signature visual, ported from the Kotlin `DeviceHeroCard`.
///
/// Four live readings sit around the device photo, two above and two below,
/// each row joined to the photo by two differently curved wires. The wires
/// march (animated mint dashes) while the device [isRunning] and sit still as a
/// muted hairline when it stops: the motion IS the "is it live" signal, so a
/// stopped device never gets a faked animation.
///
/// Exactly 4 [callouts] are expected, in top-left, top-right, bottom-left,
/// bottom-right order. [todaySummary] is a separate row below: "what it has
/// done today" is a different question from "what it is doing right now".
class DeviceHeroCard extends StatefulWidget {
  const DeviceHeroCard({
    super.key,
    required this.kind,
    required this.isRunning,
    required this.callouts,
    required this.todaySummary,
    this.comingSoon = false,
  });

  final DeviceKind kind;
  final bool isRunning;
  final List<HeroCallout> callouts;
  final List<HeroMetric> todaySummary;
  final bool comingSoon;

  @override
  State<DeviceHeroCard> createState() => _DeviceHeroCardState();
}

class _DeviceHeroCardState extends State<DeviceHeroCard> with SingleTickerProviderStateMixin {
  late final AnimationController _flow = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 750),
  );

  bool get _live => widget.isRunning && !widget.comingSoon;

  @override
  void initState() {
    super.initState();
    _syncAnimation();
  }

  @override
  void didUpdateWidget(DeviceHeroCard old) {
    super.didUpdateWidget(old);
    _syncAnimation();
  }

  void _syncAnimation() {
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
    final c = widget.callouts;
    final muted = widget.comingSoon;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (c.length >= 2) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _CalloutColumn(callout: c[0], muted: muted, alignEnd: false),
              _CalloutColumn(callout: c[1], muted: muted, alignEnd: true),
            ],
          ),
          _WireRow(intoDevice: true, live: _live, flow: _flow),
        ],
        _HeroImage(kind: widget.kind, comingSoon: widget.comingSoon),
        if (c.length >= 4) ...[
          _WireRow(intoDevice: false, live: _live, flow: _flow),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CalloutColumn(callout: c[2], muted: muted, alignEnd: false),
              _CalloutColumn(callout: c[3], muted: muted, alignEnd: true),
            ],
          ),
        ],
        if (widget.todaySummary.isNotEmpty) ...[
          const SizedBox(height: ClaroSpacing.lg),
          Row(
            children: [
              for (var i = 0; i < widget.todaySummary.length; i++) ...[
                if (i > 0) const SizedBox(width: ClaroSpacing.md),
                Expanded(child: _TodaySummaryTile(metric: widget.todaySummary[i])),
              ],
            ],
          ),
        ],
      ],
    );
  }
}

/// Every hero photo sits directly on the screen background ([ClaroColors.ink]),
/// never a lighter panel, which would read as letterboxing. The pump image is a
/// transparent cutout, so it is inset and fitted; the inverter image is a full
/// scene with its own backdrop, so it fills the box edge to edge.
class _HeroImage extends StatelessWidget {
  const _HeroImage({required this.kind, required this.comingSoon});

  final DeviceKind kind;
  final bool comingSoon;

  @override
  Widget build(BuildContext context) {
    final isInverter = kind == DeviceKind.inverter;
    return ClipRRect(
      borderRadius: ClaroRadius.lg,
      child: Container(
        height: 180,
        color: ClaroColors.ink,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (isInverter)
              Image.asset(
                'assets/images/device_hero_inverter.png',
                fit: BoxFit.cover,
                semanticLabel: 'Solar inverter system',
              )
            else
              Center(
                child: FractionallySizedBox(
                  widthFactor: 0.72,
                  heightFactor: 0.92,
                  child: Image.asset(
                    'assets/images/device_hero_pump.png',
                    fit: BoxFit.contain,
                    semanticLabel: 'Solar pump system',
                  ),
                ),
              ),
            if (isInverter && comingSoon)
              const Align(alignment: Alignment.bottomCenter, child: _ComingSoonTag()),
          ],
        ),
      ),
    );
  }
}

class _ComingSoonTag extends StatelessWidget {
  const _ComingSoonTag();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: ClaroSpacing.sm),
      padding: const EdgeInsets.symmetric(horizontal: ClaroSpacing.md, vertical: ClaroSpacing.xs),
      decoration: BoxDecoration(
        color: ClaroColors.ink.withValues(alpha: 0.72),
        borderRadius: ClaroRadius.pill,
      ),
      child: Text(
        'Full readings coming soon',
        style: ClaroType.caption.copyWith(color: ClaroColors.mint),
      ),
    );
  }
}

class _CalloutColumn extends StatelessWidget {
  const _CalloutColumn({required this.callout, required this.muted, required this.alignEnd});

  final HeroCallout callout;
  final bool muted;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    // A real reading gets the big readout. The "no data" dash deliberately does
    // not: blown up to 28 next to a 14 unit it reads as a broken sliver. At unit
    // size it reads as a calm "— kW": clearly "nothing here".
    final hasValue = callout.value != noData;
    final valueColor = muted || !hasValue ? context.textSecondary : context.textPrimary;
    return Column(
      crossAxisAlignment: alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              callout.value,
              style: (hasValue ? ClaroType.readoutLg : ClaroType.body).copyWith(color: valueColor),
            ),
            const SizedBox(width: 4),
            Text(callout.unit, style: ClaroType.body.copyWith(color: context.textSecondary)),
          ],
        ),
        Text(callout.label.toUpperCase(), style: ClaroType.label.copyWith(color: context.textSecondary)),
      ],
    );
  }
}

class _TodaySummaryTile extends StatelessWidget {
  const _TodaySummaryTile({required this.metric});

  final HeroMetric metric;

  @override
  Widget build(BuildContext context) {
    final hasValue = metric.value != noData;
    return Container(
      padding: const EdgeInsets.all(ClaroSpacing.md),
      decoration: BoxDecoration(color: context.panel, borderRadius: ClaroRadius.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(metric.label, style: ClaroType.caption.copyWith(color: context.textSecondary)),
          const SizedBox(height: ClaroSpacing.xs),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: Text(
                  metric.value,
                  overflow: TextOverflow.ellipsis,
                  style: ClaroType.readout.copyWith(
                    color: hasValue ? context.textPrimary : context.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Text(metric.unit, style: ClaroType.caption.copyWith(color: context.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }
}

/// Two curved wires between a callout row and the photo. Deliberately NOT a
/// mirrored pair: real wires take different routes to different terminals.
/// [intoDevice] decides which end touches the photo.
class _WireRow extends StatelessWidget {
  const _WireRow({required this.intoDevice, required this.live, required this.flow});

  final bool intoDevice;
  final bool live;
  final Animation<double> flow;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 22,
      child: AnimatedBuilder(
        animation: flow,
        builder: (context, _) => CustomPaint(
          painter: _WirePainter(
            intoDevice: intoDevice,
            live: live,
            // Same as the Kotlin animation: the dash phase moves 0 → -22 every 750 ms.
            phase: live ? -22 * flow.value : 0,
          ),
        ),
      ),
    );
  }
}

class _WirePainter extends CustomPainter {
  _WirePainter({required this.intoDevice, required this.live, required this.phase});

  final bool intoDevice;
  final bool live;
  final double phase;

  @override
  void paint(Canvas canvas, Size size) {
    final calloutY = intoDevice ? 0.0 : size.height;
    final deviceY = intoDevice ? size.height : 0.0;
    double lerp(double a, double b, double t) => a + (b - a) * t;

    final paint = Paint()
      ..color = live ? ClaroColors.mint : ClaroColors.borderDark
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;

    // Left wire: starts under the left callout, bows gently, lands left of centre.
    final leftStartX = size.width * 0.18;
    final leftEndX = size.width * 0.40;
    final left = Path()
      ..moveTo(leftStartX, calloutY)
      ..cubicTo(
        leftStartX,
        lerp(calloutY, deviceY, 0.35),
        leftStartX + (leftEndX - leftStartX) * 0.7,
        lerp(calloutY, deviceY, 0.8),
        leftEndX,
        deviceY,
      );

    // Right wire: a different curve and landing point, not the left one mirrored.
    final rightStartX = size.width * 0.82;
    final rightEndX = size.width * 0.62;
    final right = Path()
      ..moveTo(rightStartX, calloutY)
      ..cubicTo(
        rightStartX,
        lerp(calloutY, deviceY, 0.55),
        rightStartX + (rightEndX - rightStartX) * 0.35,
        lerp(calloutY, deviceY, 0.9),
        rightEndX,
        deviceY,
      );

    drawDashedPath(canvas, left, paint, dash: 6, gap: 5, phase: phase);
    drawDashedPath(canvas, right, paint, dash: 6, gap: 5, phase: phase);
  }

  @override
  bool shouldRepaint(_WirePainter old) =>
      old.phase != phase || old.live != live || old.intoDevice != intoDevice;
}
