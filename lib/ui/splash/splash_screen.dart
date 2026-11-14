import 'package:material_ui/material_ui.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../app/theme/claro_colors.dart';
import '../../app/theme/claro_dimens.dart';
import '../../app/theme/claro_type.dart';
import '../components/claro_powered_by.dart';

/// Shown for a moment at start-up while the app gets ready: the logo with
/// slow red "pulse" rings (the app is called Pulse), and Claro Energy below.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _rings = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..repeat();

  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  )..forward();

  @override
  void dispose() {
    _rings.dispose();
    _intro.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fade = CurvedAnimation(parent: _intro, curve: Curves.easeOut);
    return Scaffold(
      backgroundColor: ClaroColors.ink,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: FadeTransition(
                opacity: fade,
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.92, end: 1).animate(fade),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox.square(
                        dimension: 200,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            AnimatedBuilder(
                              animation: _rings,
                              builder: (context, _) => CustomPaint(
                                size: const Size.square(200),
                                painter: _PulseRings(_rings.value),
                              ),
                            ),
                            Container(
                              width: 96,
                              height: 96,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: ClaroColors.inkPanel,
                                border: Border.all(
                                  color: ClaroColors.brand.withValues(
                                    alpha: 0.6,
                                  ),
                                  width: 1.5,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: SvgPicture.asset(
                                'assets/logos/claro_logomark_white.svg',
                                width: 48,
                                height: 48,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: ClaroSpacing.xl),
                      Text(
                        'Claro Pulse',
                        style: ClaroType.displayLg.copyWith(
                          color: ClaroColors.onInk,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: ClaroSpacing.xs),
                      Text(
                        'Smart solar pumping',
                        style: ClaroType.body.copyWith(
                          color: ClaroColors.brandBright.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(bottom: ClaroSpacing.xxl),
              child: ClaroPoweredBy(captionColor: ClaroColors.onInkMuted),
            ),
          ],
        ),
      ),
    );
  }
}

/// Three red rings expanding outward and fading, one after another.
class _PulseRings extends CustomPainter {
  _PulseRings(this.t);

  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final maxRadius = size.shortestSide / 2;
    for (var i = 0; i < 3; i++) {
      final phase = (t + i / 3) % 1.0;
      final radius = 48 + (maxRadius - 48) * phase;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = ClaroColors.brand.withValues(alpha: (1 - phase) * 0.55);
      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(_PulseRings old) => old.t != t;
}
