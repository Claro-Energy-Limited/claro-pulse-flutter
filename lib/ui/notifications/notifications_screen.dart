import 'package:flutter/material.dart';

import '../../app/theme/claro_colors.dart';
import '../../app/theme/claro_dimens.dart';
import '../../app/theme/claro_type.dart';
import '../../core/api/models/pump_models.dart';
import '../../core/util/relative_time.dart';
import '../common/ui_kit.dart';

/// Alerts: what happened with the pump and complaints, newest first, in plain words.
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key, required this.notifications, required this.onBack});

  final List<AppNotification>? notifications;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final items = notifications;
    return Scaffold(
      backgroundColor: context.bg,
      body: SafeArea(
        child: Column(
          children: [
            BackHeader(title: 'Alerts', onBack: onBack),
            Expanded(
              child: items == null
                  ? Center(child: CircularProgressIndicator(color: context.brandMint))
                  : items.isEmpty
                      ? const Center(
                          child: MessageState(
                            icon: Icons.notifications_none_rounded,
                            title: 'All quiet',
                            message: "We'll let you know here if anything needs your attention.",
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(
                            ClaroSpacing.xl,
                            ClaroSpacing.sm,
                            ClaroSpacing.xl,
                            ClaroSpacing.xxl,
                          ),
                          itemCount: items.length,
                          separatorBuilder: (_, _) => const SizedBox(height: ClaroSpacing.md),
                          itemBuilder: (context, i) => _AlertTile(item: items[i]),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AlertTile extends StatelessWidget {
  const _AlertTile({required this.item});

  final AppNotification item;

  @override
  Widget build(BuildContext context) {
    final (IconData icon, Color color) = switch (item.kind) {
      NotificationKind.fault => (Icons.warning_amber_rounded, ClaroColors.fault),
      NotificationKind.offline => (Icons.wifi_off_rounded, ClaroColors.warn),
      NotificationKind.success => (Icons.water_drop_rounded, context.brandMint),
      NotificationKind.info => (Icons.support_agent_rounded, context.textPrimary),
    };
    return Panel(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color.withValues(alpha: 0.12)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: ClaroSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(item.title, style: ClaroType.subtitle.copyWith(color: context.textPrimary)),
                    ),
                    if (!item.read)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: context.brandMint),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(item.body, style: ClaroType.body.copyWith(color: context.textSecondary)),
                const SizedBox(height: ClaroSpacing.xs),
                Text(
                  formatRelativeTime(item.createdAt),
                  style: ClaroType.caption.copyWith(color: context.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
