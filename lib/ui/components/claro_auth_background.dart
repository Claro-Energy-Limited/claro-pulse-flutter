import 'package:flutter/widgets.dart';

import '../../app/theme/claro_colors.dart';

/// The sign-in backdrop, ported from the Kotlin `ClaroPulseAuthBackground`: a
/// clean dark background with the sign-in content.
class ClaroAuthBackground extends StatelessWidget {
  const ClaroAuthBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: ClaroColors.ink,
      child: child,
    );
  }
}
