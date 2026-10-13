import 'package:flutter/material.dart';

import '../../app/theme/claro_colors.dart';
import '../../app/theme/claro_dimens.dart';
import '../../app/theme/claro_type.dart';

/// The Complaints tab, ported from the Kotlin `ComplaintsTabContent`.
///
/// Deliberately not built out yet, exactly like the Kotlin app: the tab exists
/// so the surface reads as intentional, but there is no form, list or backend
/// endpoint. Replace this widget's body when that work is scoped.
class ComplaintsTab extends StatelessWidget {
  const ComplaintsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(shape: BoxShape.circle, color: ClaroColors.inkPanel),
            child: const Icon(Icons.warning, color: ClaroColors.onInkMuted, size: 28),
          ),
          const SizedBox(height: ClaroSpacing.lg),
          Text('Complaints', style: ClaroType.title.copyWith(color: ClaroColors.onInk)),
          const SizedBox(height: ClaroSpacing.xs),
          Text('Coming soon.', style: ClaroType.body.copyWith(color: ClaroColors.onInkMuted)),
        ],
      ),
    );
  }
}
