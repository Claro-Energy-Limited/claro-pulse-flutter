import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../app/theme/claro_dimens.dart';

// The app's thin-line icon set, ported from the Kotlin `ClaroPulseIcons.kt`.
//
// Hand-drawn rather than taken from an icon pack, so domain icons (solar panel,
// battery, grid) and navigation icons share one visual language. Every icon
// draws proportionally to the size the caller picks.

typedef _IconPainterFn = void Function(Canvas canvas, Size size, Color color);

class _CanvasIcon extends StatelessWidget {
  const _CanvasIcon({required this.size, required this.color, required this.draw});

  final double size;
  final Color color;
  final _IconPainterFn draw;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: Size.square(size), painter: _FnPainter(draw, color));
  }
}

class _FnPainter extends CustomPainter {
  _FnPainter(this.draw, this.color);

  final _IconPainterFn draw;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) => draw(canvas, size, color);

  @override
  bool shouldRepaint(_FnPainter old) => old.color != color || old.draw != draw;
}

const _white = Color(0xFFFFFFFF);

Paint _stroke(Color c, double width, {StrokeJoin join = StrokeJoin.miter}) => Paint()
  ..color = c
  ..style = PaintingStyle.stroke
  ..strokeWidth = width
  ..strokeCap = StrokeCap.round
  ..strokeJoin = join;

Paint _fill(Color c) => Paint()..color = c;

/// A straight line with butt ends, matching Compose's `drawLine` default.
void _line(Canvas canvas, Offset a, Offset b, Color c, double width, {bool round = false}) {
  canvas.drawLine(
    a,
    b,
    Paint()
      ..color = c
      ..strokeWidth = width
      ..strokeCap = round ? StrokeCap.round : StrokeCap.butt,
  );
}

Offset _lerp(Offset a, Offset b, double t) => Offset.lerp(a, b, t)!;

double _rad(double degrees) => degrees * math.pi / 180;

// ── Domain icons ────────────────────────────────────────────────────────────

class SolarPanelIcon extends StatelessWidget {
  const SolarPanelIcon({super.key, this.size = 24, this.color = _white});
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => _CanvasIcon(size: size, color: color, draw: _draw);

  static void _draw(Canvas canvas, Size s, Color c) {
    const sw = ClaroStroke.thin;
    final w = s.width, h = s.height;
    // A slight parallelogram skew reads as a tilted panel, not a flat rectangle.
    final topLeft = Offset(w * 0.12, h * 0.12);
    final topRight = Offset(w * 0.92, h * 0.02);
    final bottomRight = Offset(w * 0.8, h * 0.9);
    final bottomLeft = Offset(0, h);
    final outline = Path()
      ..moveTo(topLeft.dx, topLeft.dy)
      ..lineTo(topRight.dx, topRight.dy)
      ..lineTo(bottomRight.dx, bottomRight.dy)
      ..lineTo(bottomLeft.dx, bottomLeft.dy)
      ..close();
    canvas.drawPath(outline, _stroke(c, sw));
    // Two grid lines each way read as cells without drawing all six.
    for (var i = 1; i <= 2; i++) {
      final t = i / 3;
      _line(canvas, _lerp(topLeft, bottomLeft, t), _lerp(topRight, bottomRight, t), c, sw);
      _line(canvas, _lerp(topLeft, topRight, t), _lerp(bottomLeft, bottomRight, t), c, sw);
    }
  }
}

class BatteryIcon extends StatelessWidget {
  const BatteryIcon({super.key, this.size = 24, this.color = _white});
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => _CanvasIcon(size: size, color: color, draw: _draw);

  static void _draw(Canvas canvas, Size s, Color c) {
    final w = s.width, h = s.height;
    final bodyWidth = w * 0.82;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTRB(0, h * 0.12, bodyWidth, h * 0.88), Radius.circular(w * 0.12)),
      _stroke(c, ClaroStroke.thin),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(bodyWidth + w * 0.02, h * 0.35, w * 0.1, h * 0.3),
        Radius.circular(w * 0.03),
      ),
      _fill(c),
    );
    // A filled bolt: the one accent inside an otherwise outlined mark.
    final bolt = Path()
      ..moveTo(bodyWidth * 0.56, h * 0.22)
      ..lineTo(bodyWidth * 0.32, h * 0.56)
      ..lineTo(bodyWidth * 0.48, h * 0.56)
      ..lineTo(bodyWidth * 0.4, h * 0.82)
      ..lineTo(bodyWidth * 0.66, h * 0.44)
      ..lineTo(bodyWidth * 0.5, h * 0.44)
      ..close();
    canvas.drawPath(bolt, _fill(c));
  }
}

class LoadIcon extends StatelessWidget {
  const LoadIcon({super.key, this.size = 24, this.color = _white});
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => _CanvasIcon(size: size, color: color, draw: _draw);

  static void _draw(Canvas canvas, Size s, Color c) {
    const sw = ClaroStroke.thin;
    final center = Offset(s.width / 2, s.height * 0.58);
    final r = s.shortestSide * 0.42;
    canvas.drawArc(Rect.fromCircle(center: center, radius: r), _rad(160), _rad(220), false, _stroke(c, sw));
    final needle = _rad(45);
    _line(
      canvas,
      center,
      Offset(center.dx + r * 0.68 * math.cos(needle), center.dy - r * 0.68 * math.sin(needle)),
      c,
      sw,
      round: true,
    );
    canvas.drawCircle(center, s.shortestSide * 0.045, _fill(c));
  }
}

class ClockIcon extends StatelessWidget {
  const ClockIcon({super.key, this.size = 24, this.color = _white});
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => _CanvasIcon(size: size, color: color, draw: _draw);

  static void _draw(Canvas canvas, Size s, Color c) {
    const sw = ClaroStroke.thin;
    final center = s.center(Offset.zero);
    final r = s.shortestSide * 0.42;
    canvas.drawCircle(center, r, _stroke(c, sw));
    _line(canvas, center, Offset(center.dx, center.dy - r * 0.55), c, sw);
    _line(canvas, center, Offset(center.dx + r * 0.4, center.dy), c, sw);
  }
}

class WaterDropIcon extends StatelessWidget {
  const WaterDropIcon({super.key, this.size = 24, this.color = _white});
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => _CanvasIcon(size: size, color: color, draw: _draw);

  static void _draw(Canvas canvas, Size s, Color c) {
    final w = s.width, h = s.height;
    final path = Path()
      ..moveTo(w / 2, h * 0.04)
      ..cubicTo(w * 0.92, h * 0.55, w * 0.8, h * 0.96, w / 2, h * 0.96)
      ..cubicTo(w * 0.2, h * 0.96, w * 0.08, h * 0.55, w / 2, h * 0.04)
      ..close();
    canvas.drawPath(path, _stroke(c, ClaroStroke.thin, join: StrokeJoin.round));
  }
}

class EvseIcon extends StatelessWidget {
  const EvseIcon({super.key, this.size = 24, this.color = _white});
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => _CanvasIcon(size: size, color: color, draw: _draw);

  static void _draw(Canvas canvas, Size s, Color c) {
    const sw = ClaroStroke.thin;
    final w = s.width, h = s.height;
    final body = Rect.fromLTRB(w * 0.18, h * 0.06, w * 0.82, h * 0.62);
    canvas.drawRRect(RRect.fromRectAndRadius(body, Radius.circular(w * 0.08)), _stroke(c, sw));
    // Two prongs.
    _line(canvas, Offset(w * 0.38, body.bottom), Offset(w * 0.38, h * 0.82), c, sw, round: true);
    _line(canvas, Offset(w * 0.62, body.bottom), Offset(w * 0.62, h * 0.82), c, sw, round: true);
    // Cable curling off to the side.
    final cable = Path()
      ..moveTo(body.left, h * 0.3)
      ..cubicTo(w * -0.05, h * 0.3, w * -0.05, h * 0.55, w * 0.12, h * 0.52);
    canvas.drawPath(cable, _stroke(c, sw));
  }
}

class GridTowerIcon extends StatelessWidget {
  const GridTowerIcon({super.key, this.size = 24, this.color = _white});
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => _CanvasIcon(size: size, color: color, draw: _draw);

  static void _draw(Canvas canvas, Size s, Color c) {
    const sw = ClaroStroke.thin;
    final w = s.width, h = s.height;
    final apex = Offset(w / 2, 0);
    final baseLeft = Offset(w * 0.08, h);
    final baseRight = Offset(w * 0.92, h);
    _line(canvas, apex, baseLeft, c, sw);
    _line(canvas, apex, baseRight, c, sw);
    // Cross braces, narrowing toward the apex.
    for (final t in const [0.35, 0.6, 0.82]) {
      _line(canvas, _lerp(apex, baseLeft, t), _lerp(apex, baseRight, t), c, sw * 0.85);
    }
    // Wire arm and insulator dots near the top.
    _line(canvas, Offset(w * 0.12, h * 0.1), Offset(w * 0.88, h * 0.1), c, sw * 0.85);
    canvas.drawCircle(Offset(w * 0.12, h * 0.1), w * 0.03, _fill(c));
    canvas.drawCircle(Offset(w * 0.88, h * 0.1), w * 0.03, _fill(c));
  }
}

// ── Bottom navigation icons: same line language, simpler forms ────────────────

class NavHomeIcon extends StatelessWidget {
  const NavHomeIcon({super.key, this.size = 24, this.color = _white});
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => _CanvasIcon(size: size, color: color, draw: _draw);

  static void _draw(Canvas canvas, Size s, Color c) {
    const sw = ClaroStroke.regular;
    final w = s.width, h = s.height;
    final path = Path()
      ..moveTo(w * 0.06, h * 0.48)
      ..lineTo(w / 2, h * 0.05)
      ..lineTo(w * 0.94, h * 0.48)
      ..lineTo(w * 0.8, h * 0.95)
      ..lineTo(w * 0.2, h * 0.95)
      ..close();
    canvas.drawPath(path, _stroke(c, sw, join: StrokeJoin.round));
    _line(canvas, Offset(w * 0.42, h * 0.95), Offset(w * 0.42, h * 0.62), c, sw);
    _line(canvas, Offset(w * 0.58, h * 0.95), Offset(w * 0.58, h * 0.62), c, sw);
    _line(canvas, Offset(w * 0.42, h * 0.62), Offset(w * 0.58, h * 0.62), c, sw);
  }
}

class NavAnalyticsIcon extends StatelessWidget {
  const NavAnalyticsIcon({super.key, this.size = 24, this.color = _white});
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => _CanvasIcon(size: size, color: color, draw: _draw);

  static void _draw(Canvas canvas, Size s, Color c) {
    final d = s.shortestSide * 0.82;
    final rect = Rect.fromCenter(center: s.center(Offset.zero), width: d, height: d);
    canvas.drawArc(rect, _rad(-90), _rad(260), false, _stroke(c, ClaroStroke.regular));
  }
}

class NavGridIcon extends StatelessWidget {
  const NavGridIcon({super.key, this.size = 24, this.color = _white});
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => _CanvasIcon(size: size, color: color, draw: _draw);

  static void _draw(Canvas canvas, Size s, Color c) {
    final cell = s.shortestSide * 0.34;
    final gap = s.shortestSide * 0.12;
    final startX = (s.width - (cell * 2 + gap)) / 2;
    final startY = (s.height - (cell * 2 + gap)) / 2;
    for (var row = 0; row < 2; row++) {
      for (var col = 0; col < 2; col++) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(startX + col * (cell + gap), startY + row * (cell + gap), cell, cell),
            Radius.circular(cell * 0.22),
          ),
          _fill(c),
        );
      }
    }
  }
}

class NavWalletIcon extends StatelessWidget {
  const NavWalletIcon({super.key, this.size = 24, this.color = _white});
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => _CanvasIcon(size: size, color: color, draw: _draw);

  static void _draw(Canvas canvas, Size s, Color c) {
    const sw = ClaroStroke.regular;
    final w = s.width, h = s.height;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTRB(0, h * 0.18, w, h * 0.86), Radius.circular(w * 0.14)),
      _stroke(c, sw),
    );
    _line(canvas, Offset(0, h * 0.42), Offset(w, h * 0.42), c, sw);
    canvas.drawCircle(Offset(w * 0.78, h * 0.64), w * 0.06, _fill(c));
  }
}

class NavProfileIcon extends StatelessWidget {
  const NavProfileIcon({super.key, this.size = 24, this.color = _white});
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => _CanvasIcon(size: size, color: color, draw: _draw);

  static void _draw(Canvas canvas, Size s, Color c) {
    const sw = ClaroStroke.regular;
    final w = s.width, h = s.height;
    canvas.drawCircle(Offset(w / 2, h * 0.32), s.shortestSide * 0.18, _stroke(c, sw));
    final shoulders = Path()
      ..moveTo(w * 0.18, h * 0.92)
      ..cubicTo(w * 0.18, h * 0.6, w * 0.82, h * 0.6, w * 0.82, h * 0.92);
    canvas.drawPath(shoulders, _stroke(c, sw));
  }
}
