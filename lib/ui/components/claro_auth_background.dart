import 'package:flutter/widgets.dart';

import '../../app/theme/claro_colors.dart';

/// The sign-in backdrop, ported from the Kotlin `ClaroPulseAuthBackground`: a
/// photo cropped for portrait phones, with a thin dark scrim over the top 30%
/// so the white logo text stays readable on the photo's bright corner.
class ClaroAuthBackground extends StatelessWidget {
  const ClaroAuthBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset('assets/images/auth_background.jpg', fit: BoxFit.cover),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [ClaroColors.ink.withValues(alpha: 0.28), ClaroColors.ink.withValues(alpha: 0)],
              stops: const [0, 0.3],
            ),
          ),
        ),
        child,
      ],
    );
  }
}
