import 'package:flutter/widgets.dart';

import '../../app/theme/claro_colors.dart';
import '../../app/theme/claro_type.dart';

/// A labelled live reading, ported from the Kotlin `ClaroPulseDataReadout`.
///
/// Every live number renders in JetBrains Mono with tabular figures, so a kW
/// value reads as an instrument reading rather than decorative text.
class ClaroDataReadout extends StatelessWidget {
  const ClaroDataReadout({
    super.key,
    required this.label,
    required this.value,
    required this.unit,
    this.icon,
    this.labelColor = ClaroColors.onInkMuted,
    this.valueColor = ClaroColors.onInk,
    this.valueStyle,
  });

  final String label;
  final String value;
  final String unit;
  final Widget? icon;
  final Color labelColor;
  final Color valueColor;

  /// Defaults to [ClaroType.readoutLg].
  final TextStyle? valueStyle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: ClaroType.caption.copyWith(color: labelColor)),
        const SizedBox(height: 6),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[icon!, const SizedBox(width: 6)],
            Text(value, style: (valueStyle ?? ClaroType.readoutLg).copyWith(color: valueColor)),
            const SizedBox(width: 4),
            Text(unit, style: ClaroType.body.copyWith(color: labelColor)),
          ],
        ),
      ],
    );
  }
}
