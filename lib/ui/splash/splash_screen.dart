import 'package:flutter/material.dart';

import '../../app/theme/claro_colors.dart';
import '../../app/theme/claro_dimens.dart';
import '../../app/theme/claro_type.dart';
import '../components/claro_powered_by.dart';

/// Shown for a moment at start-up while the app gets ready: the Claro Energy
/// flash card with animated mint accents and app details, and Claro Powered By below.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2000),
  )..repeat(reverse: true);

  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  )..forward();

  @override
  void dispose() {
    _pulse.dispose();
    _intro.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fade = CurvedAnimation(parent: _intro, curve: Curves.easeOut);
    return Scaffold(
      backgroundColor: context.bg,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: FadeTransition(
                opacity: fade,
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.92, end: 1).animate(fade),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: ClaroSpacing.xl),
                      child: AnimatedBuilder(
                        animation: _pulse,
                        builder: (context, child) => _ClaroEnergyFlashCard(pulseValue: _pulse.value),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: ClaroSpacing.xxl),
              child: ClaroPoweredBy(captionColor: context.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _ClaroEnergyFlashCard extends StatelessWidget {
  const _ClaroEnergyFlashCard({required this.pulseValue});

  final double pulseValue;

  @override
  Widget build(BuildContext context) {
    final glowAlpha = 0.10 + (0.15 * pulseValue);
    final borderAlpha = 0.35 + (0.25 * pulseValue);

    return Container(
      constraints: const BoxConstraints(maxWidth: 320),
      padding: const EdgeInsets.symmetric(horizontal: ClaroSpacing.xl, vertical: ClaroSpacing.xxl),
      decoration: BoxDecoration(
        color: context.panel,
        borderRadius: ClaroRadius.lg,
        border: Border.all(
          color: context.brandMint.withValues(alpha: borderAlpha),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: context.brandMint.withValues(alpha: glowAlpha),
            blurRadius: 28,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Claro Pulse',
            style: ClaroType.displayLg.copyWith(
              color: context.textPrimary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: ClaroSpacing.xs),
          Text(
            'Smart solar pumping',
            style: ClaroType.body.copyWith(
              color: context.brandMint,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
