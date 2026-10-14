import 'package:flutter/widgets.dart';

import '../../app/theme/claro_colors.dart';
import '../../app/theme/claro_type.dart';

/// "Updated 2 min ago", ported from the Kotlin `ClaroPulseFreshnessStamp`.
///
/// Shown next to every reading so a stale value is never mistaken for a live one.
/// The dot is mint when the data is current and grey when it may not be.
class ClaroFreshnessStamp extends StatelessWidget {
  const ClaroFreshnessStamp({super.key, required this.text, this.isLive = true});

  final String text;
  final bool isLive;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isLive ? context.brandMint : ClaroColors.muted,
          ),
        ),
        const SizedBox(width: 6),
        Text(text, style: ClaroType.caption.copyWith(color: context.textSecondary)),
      ],
    );
  }
}
