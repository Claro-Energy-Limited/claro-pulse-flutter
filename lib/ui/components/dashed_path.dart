import 'dart:ui';

/// Draws [path] as a dashed line: [dash] on, [gap] off, starting [phase] units
/// into the pattern. Shifting the phase over time makes the dashes march, the
/// same effect as Compose's `PathEffect.dashPathEffect(intervals, phase)`.
void drawDashedPath(
  Canvas canvas,
  Path path,
  Paint paint, {
  required double dash,
  required double gap,
  double phase = 0,
}) {
  final cycle = dash + gap;
  for (final metric in path.computeMetrics()) {
    // Dart's % is always non-negative for a positive divisor.
    var start = -(phase % cycle);
    while (start < metric.length) {
      final end = start + dash;
      if (end > 0) {
        canvas.drawPath(
          metric.extractPath(start < 0 ? 0 : start, end > metric.length ? metric.length : end),
          paint,
        );
      }
      start += cycle;
    }
  }
}
