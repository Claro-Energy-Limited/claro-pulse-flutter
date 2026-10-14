import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../app/theme/claro_colors.dart';
import '../../app/theme/claro_dimens.dart';
import '../../app/theme/claro_type.dart';
import '../common/ui_kit.dart';
import '../components/claro_powered_by.dart';
import '../dev/component_gallery_screen.dart';

/// Profile: who's signed in, their pumps, help, and log out. Nothing technical.
class ProfileTab extends StatelessWidget {
  const ProfileTab({
    super.key,
    required this.phone,
    required this.deviceCount,
    required this.isDemo,
    required this.onOpenDevices,
    required this.onOpenComplaints,
    required this.onLogout,
  });

  final String? phone;
  final int deviceCount;
  final bool isDemo;
  final VoidCallback onOpenDevices;
  final VoidCallback onOpenComplaints;
  final VoidCallback onLogout;

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ClaroColors.inkPanel,
        title: Text('Log out?', style: ClaroType.title.copyWith(color: ClaroColors.onInk)),
        content: Text(
          "You'll need your phone number and a new code to sign in again.",
          style: ClaroType.body.copyWith(color: ClaroColors.onInkMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel', style: ClaroType.label.copyWith(color: ClaroColors.onInkMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Log out', style: ClaroType.label.copyWith(color: ClaroColors.fault)),
          ),
        ],
      ),
    );
    if (confirmed == true) onLogout();
  }

  void _comingSoon(BuildContext context, String what) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$what is coming soon')));
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(ClaroSpacing.xl, ClaroSpacing.lg, ClaroSpacing.xl, ClaroSpacing.xxl),
        children: [
          Text('Profile', style: ClaroType.displayLg.copyWith(color: ClaroColors.onInk, fontSize: 28)),
          const SizedBox(height: ClaroSpacing.xl),
          Panel(
            padding: const EdgeInsets.all(ClaroSpacing.xl),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: ClaroColors.mint.withValues(alpha: 0.14),
                    border: Border.all(color: ClaroColors.mint.withValues(alpha: 0.4)),
                  ),
                  child: const Icon(Icons.person_rounded, color: ClaroColors.mint, size: 28),
                ),
                const SizedBox(width: ClaroSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        phone == null ? 'Signed in' : '+91 $phone',
                        style: ClaroType.title.copyWith(color: ClaroColors.onInk),
                      ),
                      Text('Claro Pulse account', style: ClaroType.caption.copyWith(color: ClaroColors.onInkMuted)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: ClaroSpacing.xl),
          _Menu(items: [
            _MenuItem(
              icon: Icons.water_drop_outlined,
              label: 'My devices',
              trailing: '$deviceCount',
              onTap: onOpenDevices,
            ),
            _MenuItem(
              icon: Icons.support_agent_rounded,
              label: 'Help & complaints',
              onTap: onOpenComplaints,
            ),
            _MenuItem(
              icon: Icons.translate_rounded,
              label: 'Language',
              trailing: 'English',
              onTap: () => _comingSoon(context, 'Choosing a language'),
            ),
            _MenuItem(
              icon: Icons.notifications_none_rounded,
              label: 'Notification settings',
              onTap: () => _comingSoon(context, 'Notification settings'),
            ),
          ]),
          const SizedBox(height: ClaroSpacing.lg),
          _Menu(items: [
            _MenuItem(
              icon: Icons.logout_rounded,
              label: 'Log out',
              color: ClaroColors.fault,
              onTap: () => _confirmLogout(context),
            ),
          ]),
          if (isDemo) ...[
            const SizedBox(height: ClaroSpacing.lg),
            Text(
              'Demo mode: showing sample data.',
              textAlign: TextAlign.center,
              style: ClaroType.caption.copyWith(color: ClaroColors.warn),
            ),
          ],
          const SizedBox(height: ClaroSpacing.xxl),
          const Center(child: ClaroPoweredBy(captionColor: ClaroColors.onInkMuted)),
          const SizedBox(height: ClaroSpacing.md),
          Text(
            'Claro Pulse',
            textAlign: TextAlign.center,
            style: ClaroType.caption.copyWith(color: ClaroColors.onInkMuted),
          ),
          // Developer-only shortcut, never in release builds.
          if (kDebugMode)
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
      ),
    );
  }
}

class _MenuItem {
  const _MenuItem({required this.icon, required this.label, required this.onTap, this.trailing, this.color});

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final String? trailing;
  final Color? color;
}

class _Menu extends StatelessWidget {
  const _Menu({required this.items});

  final List<_MenuItem> items;

  @override
  Widget build(BuildContext context) {
    return Panel(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const Divider(height: 1, indent: 56, color: ClaroColors.borderDark),
            InkWell(
              onTap: items[i].onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: ClaroSpacing.lg, vertical: ClaroSpacing.lg),
                child: Row(
                  children: [
                    Icon(items[i].icon, size: 22, color: items[i].color ?? ClaroColors.mint),
                    const SizedBox(width: ClaroSpacing.lg),
                    Expanded(
                      child: Text(
                        items[i].label,
                        style: ClaroType.subtitle.copyWith(color: items[i].color ?? ClaroColors.onInk),
                      ),
                    ),
                    if (items[i].trailing != null)
                      Text(items[i].trailing!, style: ClaroType.body.copyWith(color: ClaroColors.onInkMuted)),
                    if (items[i].color == null) ...[
                      const SizedBox(width: ClaroSpacing.xs),
                      const Icon(Icons.chevron_right_rounded, color: ClaroColors.onInkMuted),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
