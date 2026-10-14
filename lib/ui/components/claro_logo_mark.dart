import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../app/theme/claro_colors.dart';
import '../../app/theme/claro_dimens.dart';
import '../../app/theme/claro_type.dart';

/// The Claro Pulse brand mark, ported from the Kotlin `ClaroPulseLogoMark`: a dark
/// chip with the real Claro Energy icon plus "CLARO" / "PULSE" text. No invented
/// icon for Claro Pulse itself; only the actual Claro Energy logo asset.
class ClaroLogoMark extends StatelessWidget {
  const ClaroLogoMark({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: ClaroSpacing.md, vertical: ClaroSpacing.sm),
      decoration: BoxDecoration(
        color: context.panel,
        borderRadius: ClaroRadius.md,
        border: Border.all(color: context.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SvgPicture.asset(
            'assets/logos/claro_logomark_white.svg',
            width: 24,
            height: 24,
            semanticsLabel: 'Claro Energy',
            colorFilter: ColorFilter.mode(context.textPrimary, BlendMode.srcIn),
          ),
          const SizedBox(width: ClaroSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('CLARO', style: ClaroType.caption.copyWith(fontWeight: FontWeight.w600, color: context.brandMint)),
              Text('PULSE', style: ClaroType.subtitle.copyWith(fontWeight: FontWeight.w600, color: context.textPrimary)),
            ],
          ),
        ],
      ),
    );
  }
}
