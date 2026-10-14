import 'package:flutter/widgets.dart';

import '../../app/theme/claro_colors.dart';
import '../../app/theme/claro_dimens.dart';
import '../../app/theme/claro_type.dart';

/// The one chart used for every activity series, ported from the Kotlin
/// `ClaroPulseLineChart`.
///
/// A `null` point (a period the device never reported in) is drawn as a GAP in
/// the line: never joined across, never treated as zero. The line draws in from
/// left to right when data arrives, signalling "new data for this range".
class ClaroLineChart extends StatelessWidget {
  const ClaroLineChart({
    super.key,
    required this.points,
    required this.xLabels,
    this.height = 196,
  });

  final List<double?> points;
  final List<String> xLabels;
  final double height;

  @override
  Widget build(BuildContext context) {
    final hasAnyData = points.any((p) => p != null);
    return SizedBox(
      height: height,
      child: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: hasAnyData ? 1 : 0),
                    duration: ClaroMotion.slow,
                    builder: (context, reveal, _) => CustomPaint(
                      painter: _LineChartPainter(points: points, reveal: reveal),
                    ),
                  ),
                ),
                if (!hasAnyData)
                  Center(
                    child: Text(
                      'No data yet for this range',
                      style: ClaroType.caption.copyWith(color: context.textSecondary),
                    ),
                  ),
              ],
            ),
          ),
          if (xLabels.isNotEmpty)
            Row(
              children: [
                for (var i = 0; i < xLabels.length; i++)
                  Expanded(
                    child: Text(
                      xLabels[i],
                      textAlign: i == 0
                          ? TextAlign.start
                          : i == xLabels.length - 1
                              ? TextAlign.end
                              : TextAlign.center,
                      style: ClaroType.caption.copyWith(color: context.textSecondary),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  _LineChartPainter({required this.points, required this.reveal});

  final List<double?> points;
  final double reveal;

  @override
  void paint(Canvas canvas, Size size) {
    _drawBaseline(canvas, size);

    if (points.length < 2) return;
    final values = points.whereType<double>().toList();
    if (values.isEmpty) return;

    // Baseline at zero: these are all non-negative physical quantities.
    final maxValue = values.reduce((a, b) => a > b ? a : b);
    final range = maxValue < 0.0001 ? 0.0001 : maxValue;
    final stepX = size.width / (points.length - 1);
    double xOf(int i) => i * stepX;
    double yOf(double v) => size.height - (v / range) * size.height * 0.9 - size.height * 0.05;

    // Contiguous non-null runs only, so a gap in reporting shows as a gap.
    final line = Path();
    final fill = Path();
    var segmentOpen = false;
    var lastX = 0.0;
    for (var i = 0; i < points.length; i++) {
      final v = points[i];
      if (v == null) {
        if (segmentOpen) fill.lineTo(lastX, size.height);
        segmentOpen = false;
        continue;
      }
      final x = xOf(i);
      final y = yOf(v);
      if (!segmentOpen) {
        line.moveTo(x, y);
        fill
          ..moveTo(x, size.height)
          ..lineTo(x, y);
        segmentOpen = true;
      } else {
        line.lineTo(x, y);
        fill.lineTo(x, y);
      }
      lastX = x;
    }
    if (segmentOpen) fill.lineTo(lastX, size.height);

    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width * reveal, size.height));

    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [ClaroColors.mint.withValues(alpha: 0.28), ClaroColors.mint.withValues(alpha: 0)],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      line,
      Paint()
        ..color = ClaroColors.mint
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    final dot = Paint()..color = ClaroColors.mint;
    for (var i = 0; i < points.length; i++) {
      final v = points[i];
      if (v != null) canvas.drawCircle(Offset(xOf(i), yOf(v)), 2.6, dot);
    }
    canvas.restore();
  }

  /// Zero baseline, always visible: a dashed hairline so small values still
  /// read against a real reference line.
  void _drawBaseline(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = ClaroColors.borderDark
      ..strokeWidth = 1;
    for (var x = 0.0; x < size.width; x += 10) {
      final end = x + 4 > size.width ? size.width : x + 4;
      canvas.drawLine(Offset(x, size.height), Offset(end, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(_LineChartPainter old) => old.points != points || old.reveal != reveal;
}
