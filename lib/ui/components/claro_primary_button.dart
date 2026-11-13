import 'package:flutter/material.dart';

import '../../app/theme/claro_colors.dart';
import '../../app/theme/claro_dimens.dart';
import '../../app/theme/claro_type.dart';

/// The primary button, ported from the Kotlin `ClaroPulsePrimaryButton`.
///
/// 56 tall, larger than Material's default, for big touch targets that stay
/// usable in direct sunlight. Claro red fill with a white label: the screens run
/// black, and an ink button on an ink screen would only be findable by its text.
class ClaroPrimaryButton extends StatelessWidget {
  const ClaroPrimaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.enabled = true,
    this.loading = false,
  });

  final String text;
  final VoidCallback onPressed;
  final bool enabled;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final isEnabled = enabled && !loading;
    return Semantics(
      button: true,
      enabled: isEnabled,
      child: Material(
        color: isEnabled ? ClaroColors.brand : ClaroColors.brand.withValues(alpha: 0.25),
        borderRadius: ClaroRadius.md,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: isEnabled ? onPressed : null,
          splashColor: ClaroColors.ink.withValues(alpha: 0.12),
          highlightColor: ClaroColors.ink.withValues(alpha: 0.06),
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: Center(
              child: loading
                  ? const SizedBox.square(
                      dimension: 22,
                      child: CircularProgressIndicator(strokeWidth: 2, color: ClaroColors.onBrand),
                    )
                  : Text(
                      text,
                      style: ClaroType.subtitle.copyWith(
                        // Dimmed with the fill when disabled: full ink on a faint
                        // red would still read as a live button.
                        color: isEnabled ? ClaroColors.onBrand : ClaroColors.onInkMuted,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
