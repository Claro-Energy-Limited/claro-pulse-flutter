import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../app/theme/claro_colors.dart';
import '../../app/theme/claro_dimens.dart';
import '../../app/theme/claro_type.dart';

/// A circular percentage gauge, ported from the Kotlin `ClaroPulseGaugeRing`.
/// The arc eases to its new value so a changing number reads as a live instrument.
/// Styled for a light card, exactly as the Kotlin version is.
class ClaroGaugeRing extends StatelessWidget {
  const ClaroGaugeRing({super.key, required this.percent, required this.label, this.size = 180});

  final int percent;
  final String label;
  final double size;

  @override
  Widget build(BuildContext context) {
    final target = percent.clamp(0, 100) / 100;
    return SizedBox.square(
      dimension: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(end: target),
            duration: ClaroMotion.slow,
            builder: (context, value, _) => CustomPaint(
              size: Size.square(size),
              painter: _GaugePainter(value),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('$percent%', style: ClaroType.readoutXl.copyWith(color: ClaroColors.ink)),
              Text(label, style: ClaroType.caption.copyWith(color: ClaroColors.muted)),
            ],
          ),
        ],
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  _GaugePainter(this.fraction);

  final double fraction;

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 14.0;
    final diameter = size.shortestSide - strokeWidth;
    final rect = Rect.fromCenter(center: size.center(Offset.zero), width: diameter, height: diameter);
    Paint stroke(Color c) => Paint()
      ..color = c
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi, false, stroke(ClaroColors.border));
    if (fraction > 0) {
      canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * fraction, false, stroke(ClaroColors.mintDeep));
    }
  }

  @override
  bool shouldRepaint(_GaugePainter old) => old.fraction != fraction;
}
