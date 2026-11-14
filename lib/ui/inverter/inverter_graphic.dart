import 'package:material_ui/material_ui.dart';

import '../../app/theme/claro_colors.dart';
import '../../core/classifier/inverter_classifier.dart';

/// The central white inverter box graphic with state-colored display/LED screen.
class InverterGraphic extends StatelessWidget {
  const InverterGraphic({super.key, required this.kind});

  final InverterStateKind kind;

  @override
  Widget build(BuildContext context) {
    Color screenColor;
    switch (kind) {
      case InverterStateKind.healthy:
        screenColor = ClaroColors.mint;
      case InverterStateKind.warning:
        screenColor = ClaroColors.warn;
      case InverterStateKind.fault:
        screenColor = ClaroColors.fault;
      case InverterStateKind.resting:
      case InverterStateKind.noData:
        screenColor = const Color(0xFF8A8A85);
    }

    return Container(
      width: 110,
      height: 120,
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F0),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Screen
          Container(
            width: 48,
            height: 24,
            decoration: BoxDecoration(
              color: screenColor,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: const Color(0xFF111110).withValues(alpha: 0.15),
                width: 1,
              ),
            ),
            alignment: Alignment.center,
            child: Container(
              width: 16,
              height: 3,
              decoration: BoxDecoration(
                color: const Color(0xFF111110).withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Three LED dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < 3; i++) ...[
                if (i > 0) const SizedBox(width: 6),
                Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i == 1
                        ? screenColor
                        : const Color(0xFF111110).withValues(alpha: 0.3),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
