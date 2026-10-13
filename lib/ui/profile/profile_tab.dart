import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../app/theme/claro_colors.dart';
import '../../app/theme/claro_dimens.dart';
import '../../app/theme/claro_type.dart';
import '../dev/component_gallery_screen.dart';
import '../icons/claro_icons.dart';

/// The Profile tab, ported from the Kotlin `ProfileTabContent`.
///
/// There is no profile endpoint yet, so the phone number saved at sign-in IS
/// the identity shown here.
class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key, required this.phone, required this.onLogout});

  final String? phone;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: ClaroSpacing.xl),
      children: [
        const SizedBox(height: ClaroSpacing.lg),
        Text('Profile', style: ClaroType.title.copyWith(color: ClaroColors.onInk)),
        const SizedBox(height: ClaroSpacing.xl),
        _Panel(
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(shape: BoxShape.circle, color: ClaroColors.inkPanelHigh),
                alignment: Alignment.center,
                child: const NavProfileIcon(size: 22, color: ClaroColors.mint),
              ),
              const SizedBox(width: ClaroSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      phone == null ? 'Signed in' : '+91 $phone',
                      style: ClaroType.subtitle.copyWith(color: ClaroColors.onInk),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Claro Pulse account',
                      style: ClaroType.caption.copyWith(color: ClaroColors.onInkMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: ClaroSpacing.xl),
        _Panel(
          onTap: onLogout,
          child: Row(
            children: [
              const Icon(Icons.exit_to_app, color: ClaroColors.fault, size: 20),
              const SizedBox(width: ClaroSpacing.md),
              Text('Log out', style: ClaroType.subtitle.copyWith(color: ClaroColors.fault)),
            ],
          ),
        ),
        // Developer-only shortcut, never in release builds. Removed in phase 8.
        if (kDebugMode) ...[
          const SizedBox(height: ClaroSpacing.xxl),
          Center(
            child: TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const ComponentGalleryScreen()),
              ),
              child: Text(
                'Developer: component gallery',
                style: ClaroType.caption.copyWith(color: ClaroColors.onInkMuted),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(ClaroSpacing.lg),
        decoration: BoxDecoration(
          color: ClaroColors.inkPanel,
          borderRadius: ClaroRadius.lg,
          border: Border.all(color: ClaroColors.borderDark),
        ),
        child: child,
      ),
    );
  }
}
