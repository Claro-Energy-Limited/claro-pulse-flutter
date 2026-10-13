import 'package:flutter/material.dart';

import '../../app/theme/claro_colors.dart';
import '../../app/theme/claro_dimens.dart';
import '../../app/theme/claro_type.dart';
import '../components/claro_primary_button.dart';

// TEMPORARY. Replaced by the real add-device screens in phase 6:
//   QrScanPlaceholder, OverlayPlaceholder → phase 6

class QrScanPlaceholder extends StatelessWidget {
  const QrScanPlaceholder({super.key, required this.onEnterManually, required this.onClose});

  final VoidCallback onEnterManually;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return OverlayPlaceholder(
      title: 'Scan device QR',
      message: 'QR scanning arrives in phase 6.',
      onBack: onClose,
      action: ClaroPrimaryButton(text: 'Enter ID manually', onPressed: onEnterManually),
    );
  }
}

class OverlayPlaceholder extends StatelessWidget {
  const OverlayPlaceholder({
    super.key,
    required this.title,
    required this.message,
    required this.onBack,
    this.action,
  });

  final String title;
  final String message;
  final VoidCallback onBack;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ClaroColors.ink,
      appBar: AppBar(
        backgroundColor: ClaroColors.ink,
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: onBack, tooltip: 'Back'),
        title: Text(title, style: ClaroType.title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(ClaroSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(message, style: ClaroType.body.copyWith(color: ClaroColors.warn)),
            if (action != null) ...[const SizedBox(height: ClaroSpacing.xl), action!],
          ],
        ),
      ),
    );
  }
}
