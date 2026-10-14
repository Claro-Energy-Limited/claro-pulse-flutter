import 'package:flutter/material.dart';

import '../../app/theme/claro_colors.dart';
import '../../app/theme/claro_dimens.dart';
import '../../app/theme/claro_type.dart';

/// The primary button, ported from the Kotlin `ClaroPulsePrimaryButton`.
///
/// 56 tall, larger than Material's default, for big touch targets that stay
/// usable in direct sunlight. Mint fill with an ink label: the screens run
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
    final buttonColor = context.brandMint;
    final textColor = isEnabled
        ? (context.isDark ? ClaroColors.ink : ClaroColors.card)
        : context.textSecondary;

    return Semantics(
      button: true,
      enabled: isEnabled,
      child: Material(
        color: isEnabled ? buttonColor : buttonColor.withValues(alpha: 0.25),
        borderRadius: ClaroRadius.md,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: isEnabled ? onPressed : null,
          splashColor: textColor.withValues(alpha: 0.12),
          highlightColor: textColor.withValues(alpha: 0.06),
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: Center(
              child: loading
                  ? SizedBox.square(
                      dimension: 22,
                      child: CircularProgressIndicator(strokeWidth: 2, color: textColor),
                    )
                  : Text(
                      text,
                      style: ClaroType.subtitle.copyWith(
                        color: textColor,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
