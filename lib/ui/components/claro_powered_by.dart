import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../app/theme/claro_dimens.dart';
import '../../app/theme/claro_type.dart';

/// "POWERED BY" over the Claro Energy logo, ported from the Kotlin
/// `ClaroPulsePoweredBy`. The logo's white background plate is part of the
/// artwork, so it reads as a small badge on any backdrop.
class ClaroPoweredBy extends StatelessWidget {
  const ClaroPoweredBy({super.key, this.captionColor = const Color(0xB3FFFFFF)});

  final Color captionColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'POWERED BY',
          textAlign: TextAlign.center,
          style: ClaroType.caption.copyWith(fontWeight: FontWeight.w500, color: captionColor),
        ),
        const SizedBox(height: ClaroSpacing.sm),
        SvgPicture.asset(
          'assets/logos/claro_energy_horizontal.svg',
          width: 176,
          semanticsLabel: 'Claro Energy',
        ),
      ],
    );
  }
}
