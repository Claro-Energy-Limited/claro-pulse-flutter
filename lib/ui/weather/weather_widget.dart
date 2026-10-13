import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/theme/claro_colors.dart';
import '../../app/theme/claro_dimens.dart';
import '../../app/theme/claro_type.dart';

/// A day's weather, as the widget shows it.
///
/// Not connected to a real weather source, exactly like the Kotlin app: no
/// weather provider or location source has been chosen yet (a product
/// decision), so only [sample] exists.
class WeatherSnapshot {
  const WeatherSnapshot({required this.condition, required this.temperatureC, required this.note});

  final String condition;
  final int temperatureC;
  final String note;

  static const sample = WeatherSnapshot(
    condition: 'Sunny',
    temperatureC: 31,
    note: 'Good conditions for solar generation',
  );
}

/// The weather panel, ported from the Kotlin `WeatherWidget`. Shown only on the
/// Home tab's empty and pending-claim states.
class WeatherWidget extends StatelessWidget {
  const WeatherWidget({super.key, required this.snapshot});

  final WeatherSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
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
          const _AnimatedSun(),
          const SizedBox(width: ClaroSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${snapshot.temperatureC}°C', style: ClaroType.displayLg.copyWith(color: ClaroColors.onInk)),
                Text(snapshot.condition, style: ClaroType.subtitle.copyWith(color: ClaroColors.onInkMuted)),
                const SizedBox(height: ClaroSpacing.xs),
                Text(snapshot.note, style: ClaroType.caption.copyWith(color: ClaroColors.mint)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A slowly turning, gently pulsing sun. Slow on purpose: it's ambient
/// decoration, the only decorative animation in the app.
class _AnimatedSun extends StatefulWidget {
  const _AnimatedSun();

  @override
  State<_AnimatedSun> createState() => _AnimatedSunState();
}

class _AnimatedSunState extends State<_AnimatedSun> with TickerProviderStateMixin {
  late final AnimationController _rotation = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 12),
  )..repeat();

  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
    lowerBound: 0.85,
    upperBound: 1.0,
  )..repeat(reverse: true);

  @override
  void dispose() {
    _rotation.dispose();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 64,
      child: CustomPaint(
        painter: _SunPainter(rotation: _rotation, pulse: _pulse),
      ),
    );
  }
}

class _SunPainter extends CustomPainter {
  _SunPainter({required this.rotation, required this.pulse}) : super(repaint: Listenable.merge([rotation, pulse]));

  /// 0 → 1 per full turn.
  final Animation<double> rotation;

  /// Core scale, 0.85 ↔ 1.0.
  final Animation<double> pulse;

  @override
  void paint(Canvas canvas, Size size) {
    final m = size.shortestSide;
    final c = size.center(Offset.zero);
    final ray = Paint()
      ..color = ClaroColors.mint
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 8; i++) {
      final angle = rotation.value * 2 * math.pi + i * math.pi / 4;
      final dir = Offset(math.cos(angle), math.sin(angle));
      canvas.drawLine(c + dir * (0.36 * m), c + dir * (0.48 * m), ray);
    }
    canvas.drawCircle(c, 0.26 * m * pulse.value, Paint()..color = ClaroColors.mint);
  }

  @override
  bool shouldRepaint(_SunPainter old) => old.rotation != rotation || old.pulse != pulse;
}
