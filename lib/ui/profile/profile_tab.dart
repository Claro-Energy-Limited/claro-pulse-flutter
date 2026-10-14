import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../app/theme/claro_dimens.dart';
import '../../app/theme/claro_palette.dart';
import '../../app/theme/claro_theme.dart';
import '../../app/theme/claro_type.dart';
import '../../core/settings/app_settings.dart';
import '../common/ui_kit.dart';
import '../components/claro_powered_by.dart';
import '../dev/component_gallery_screen.dart';

String themeModeLabel(ThemeMode mode) => switch (mode) {
      ThemeMode.system => 'System default',
      ThemeMode.light => 'Light',
      ThemeMode.dark => 'Dark',
    };

/// Profile: who's signed in, their devices, appearance, help, and log out.
class ProfileTab extends StatelessWidget {
  const ProfileTab({
    super.key,
    required this.phone,
    required this.deviceCount,
    required this.isDemo,
    required this.settings,
    required this.onOpenDevices,
    required this.onOpenComplaints,
    required this.onLogout,
  });

  final String? phone;
  final int deviceCount;
  final bool isDemo;
  final AppSettings settings;
  final VoidCallback onOpenDevices;
  final VoidCallback onOpenComplaints;
  final VoidCallback onLogout;

  Future<void> _confirmLogout(BuildContext context) async {
    final p = context.palette;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: p.panel,
        title: Text('Log out?', style: ClaroType.title.copyWith(color: p.text)),
        content: Text(
          "You'll need your phone number and a new code to sign in again.",
          style: ClaroType.body.copyWith(color: p.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel', style: ClaroType.label.copyWith(color: p.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Log out', style: ClaroType.label.copyWith(color: p.faultText)),
          ),
        ],
      ),
    );
    if (confirmed == true) onLogout();
  }

  void _chooseAppearance(BuildContext context) {
    final p = context.palette;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: p.panel,
      shape: const RoundedRectangleBorder(borderRadius: ClaroRadius.sheet),
      builder: (sheetContext) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(ClaroSpacing.lg, ClaroSpacing.md, ClaroSpacing.lg, ClaroSpacing.lg),
          child: ValueListenableBuilder<ThemeMode>(
            valueListenable: settings.themeMode,
            builder: (context, current, _) {
              final sp = context.palette;
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SheetHandle(),
                  const SizedBox(height: ClaroSpacing.lg),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: ClaroSpacing.sm),
                    child: Text('Appearance', style: ClaroType.title.copyWith(color: sp.text)),
                  ),
                  const SizedBox(height: ClaroSpacing.sm),
                  for (final (mode, icon, hint) in const [
                    (ThemeMode.system, Icons.brightness_auto_rounded, "Follows your phone's setting"),
                    (ThemeMode.light, Icons.light_mode_rounded, 'Easier to read in bright sunlight'),
                    (ThemeMode.dark, Icons.dark_mode_rounded, 'Easier on the eyes at night'),
                  ])
                    ListTile(
                      shape: const RoundedRectangleBorder(borderRadius: ClaroRadius.md),
                      leading: Icon(icon, color: sp.accentText),
                      title: Text(themeModeLabel(mode), style: ClaroType.subtitle.copyWith(color: sp.text)),
                      subtitle: Text(hint, style: ClaroType.caption.copyWith(color: sp.textMuted)),
                      trailing: mode == current
                          ? Icon(Icons.check_circle_rounded, color: sp.accentText)
                          : Icon(Icons.circle_outlined, color: sp.border),
                      onTap: () {
                        settings.setThemeMode(mode);
                        Navigator.of(sheetContext).pop();
                      },
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  void _comingSoon(BuildContext context, String what) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('$what is coming soon')));
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(ClaroSpacing.xl, ClaroSpacing.lg, ClaroSpacing.xl, ClaroSpacing.xxl),
        children: [
          const PageTitle(title: 'Profile'),
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
                    color: p.accentText.withValues(alpha: 0.14),
                    border: Border.all(color: p.accentText.withValues(alpha: 0.4)),
                  ),
                  child: Icon(Icons.person_rounded, color: p.accentText, size: 28),
                ),
                const SizedBox(width: ClaroSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        phone == null ? 'Signed in' : '+91 $phone',
                        style: ClaroType.title.copyWith(color: p.text),
                      ),
                      Text('Claro Pulse account', style: ClaroType.caption.copyWith(color: p.textMuted)),
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
              label: 'Help and complaints',
              onTap: onOpenComplaints,
            ),
          ]),
          const SizedBox(height: ClaroSpacing.lg),
          ValueListenableBuilder<ThemeMode>(
            valueListenable: settings.themeMode,
            builder: (context, mode, _) => _Menu(items: [
              _MenuItem(
                icon: Icons.contrast_rounded,
                label: 'Appearance',
                trailing: themeModeLabel(mode),
                onTap: () => _chooseAppearance(context),
              ),
              _MenuItem(
                icon: Icons.translate_rounded,
                label: 'Language',
                trailing: 'English',
                onTap: () => _comingSoon(context, 'Choosing a language'),
              ),
              _MenuItem(
                icon: Icons.notifications_none_rounded,
                label: 'Notifications',
                onTap: () => _comingSoon(context, 'Notification settings'),
              ),
            ]),
          ),
          const SizedBox(height: ClaroSpacing.lg),
          _Menu(items: [
            _MenuItem(
              icon: Icons.logout_rounded,
              label: 'Log out',
              danger: true,
              onTap: () => _confirmLogout(context),
            ),
          ]),
          if (isDemo) ...[
            const SizedBox(height: ClaroSpacing.lg),
            Text(
              'Demo mode: showing sample data.',
              textAlign: TextAlign.center,
              style: ClaroType.caption.copyWith(color: p.warnText),
            ),
          ],
          const SizedBox(height: ClaroSpacing.xxl),
          Center(child: ClaroPoweredBy(captionColor: p.textMuted)),
          const SizedBox(height: ClaroSpacing.md),
          Text('Claro Pulse', textAlign: TextAlign.center, style: ClaroType.caption.copyWith(color: p.textMuted)),
          // Developer-only shortcut, never in release builds.
          if (kDebugMode)
            Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => Theme(data: ClaroTheme.dark, child: const ComponentGalleryScreen()),
                  ),
                ),
                child: Text('Developer: component gallery', style: ClaroType.caption.copyWith(color: p.textMuted)),
              ),
            ),
        ],
      ),
    );
  }
}

class _MenuItem {
  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailing,
    this.danger = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final String? trailing;
  final bool danger;
}

class _Menu extends StatelessWidget {
  const _Menu({required this.items});

  final List<_MenuItem> items;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Panel(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) Divider(height: 1, indent: 56, color: p.border),
            InkWell(
              onTap: items[i].onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: ClaroSpacing.lg, vertical: ClaroSpacing.lg),
                child: Row(
                  children: [
                    Icon(items[i].icon, size: 22, color: items[i].danger ? p.faultText : p.accentText),
                    const SizedBox(width: ClaroSpacing.lg),
                    Expanded(
                      child: Text(
                        items[i].label,
                        style: ClaroType.subtitle.copyWith(color: items[i].danger ? p.faultText : p.text),
                      ),
                    ),
                    if (items[i].trailing != null)
                      Text(items[i].trailing!, style: ClaroType.body.copyWith(color: p.textMuted)),
                    if (!items[i].danger) ...[
                      const SizedBox(width: ClaroSpacing.xs),
                      Icon(Icons.chevron_right_rounded, color: p.textMuted),
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
