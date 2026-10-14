import 'package:flutter/material.dart';

import '../../app/theme/claro_colors.dart';
import '../../app/theme/claro_dimens.dart';
import '../../app/theme/claro_type.dart';

/// The round 36px back button used by the manual-entry and claim screens.
class OnboardingBackButton extends StatelessWidget {
  const OnboardingBackButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Back',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPressed,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(shape: BoxShape.circle, color: context.panel),
          alignment: Alignment.center,
          child: Icon(Icons.keyboard_arrow_left, color: context.textPrimary, size: 22),
        ),
      ),
    );
  }
}

/// The round 40px close button on the QR screens, translucent so it reads over
/// the camera preview.
class OnboardingCloseButton extends StatelessWidget {
  const OnboardingCloseButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Close',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPressed,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: ClaroColors.ink.withValues(alpha: 0.5),
          ),
          alignment: Alignment.center,
          child: const Icon(Icons.close, color: ClaroColors.onInk, size: 20),
        ),
      ),
    );
  }
}

/// "Enter device ID manually instead": the fallback whenever scanning isn't possible.
class EnterManuallyLink extends StatelessWidget {
  const EnterManuallyLink({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onPressed,
      child: Padding(
        padding: const EdgeInsets.all(ClaroSpacing.sm),
        child: Text(
          'Enter device ID manually instead',
          style: ClaroType.label.copyWith(color: context.brandMint),
        ),
      ),
    );
  }
}
