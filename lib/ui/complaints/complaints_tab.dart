import 'package:flutter/material.dart';

import '../../app/theme/claro_colors.dart';
import '../../app/theme/claro_dimens.dart';
import '../../app/theme/claro_type.dart';
import '../../core/api/models/pump_models.dart';
import '../../core/util/relative_time.dart';
import '../common/ui_kit.dart';

/// The Complaints tab: raise a problem, and follow what's happening with it.
class ComplaintsTab extends StatelessWidget {
  const ComplaintsTab({
    super.key,
    required this.complaints,
    required this.error,
    required this.onRetry,
    required this.onRaise,
    required this.onRefresh,
  });

  /// Null while loading.
  final List<Complaint>? complaints;
  final String? error;
  final VoidCallback onRetry;
  final VoidCallback onRaise;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final complaints = this.complaints;
    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        color: ClaroColors.mint,
        backgroundColor: ClaroColors.inkPanel,
        onRefresh: onRefresh,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(ClaroSpacing.xl, ClaroSpacing.lg, ClaroSpacing.xl, ClaroSpacing.xxl),
          children: [
            Text('Complaints', style: ClaroType.displayLg.copyWith(color: ClaroColors.onInk, fontSize: 28)),
            Text(
              "Tell us what's wrong and track the fix.",
              style: ClaroType.caption.copyWith(color: ClaroColors.onInkMuted),
            ),
            const SizedBox(height: ClaroSpacing.xl),
            _RaiseCard(onTap: onRaise),
            const SizedBox(height: ClaroSpacing.xl),
            if (complaints == null && error == null)
              const SizedBox(height: 200, child: Center(child: CircularProgressIndicator(color: ClaroColors.mint)))
            else if (complaints == null)
              MessageState(
                icon: Icons.sync_problem_rounded,
                title: "Couldn't load complaints",
                message: error!,
                actionLabel: 'Try again',
                onAction: onRetry,
                isError: true,
              )
            else if (complaints.isEmpty)
              const MessageState(
                icon: Icons.thumb_up_alt_outlined,
                title: 'No complaints',
                message: "If anything goes wrong with your pump, raise it here and we'll take care of it.",
              )
            else ...[
              const SectionHeader(title: 'Your complaints'),
              const SizedBox(height: ClaroSpacing.md),
              for (final c in complaints) ...[
                ComplaintCard(complaint: c),
                const SizedBox(height: ClaroSpacing.md),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _RaiseCard extends StatelessWidget {
  const _RaiseCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Panel(
      onTap: onTap,
      color: ClaroColors.mint.withValues(alpha: 0.10),
      borderColor: ClaroColors.mint.withValues(alpha: 0.35),
      padding: const EdgeInsets.all(ClaroSpacing.lg),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(shape: BoxShape.circle, color: ClaroColors.mint),
            child: const Icon(Icons.add_rounded, color: ClaroColors.ink),
          ),
          const SizedBox(width: ClaroSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Raise a complaint', style: ClaroType.subtitle.copyWith(color: ClaroColors.onInk)),
                Text(
                  'Pump, water flow, solar panels or anything else',
                  style: ClaroType.caption.copyWith(color: ClaroColors.onInkMuted),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: ClaroColors.mint),
        ],
      ),
    );
  }
}

Color complaintStatusColor(ComplaintStatus status) => switch (status) {
      ComplaintStatus.open => ClaroColors.warn,
      ComplaintStatus.inProgress => ClaroColors.mint,
      ComplaintStatus.resolved => ClaroColors.onInkMuted,
    };

class ComplaintCard extends StatelessWidget {
  const ComplaintCard({super.key, required this.complaint});

  final Complaint complaint;

  @override
  Widget build(BuildContext context) {
    final c = complaint;
    final color = complaintStatusColor(c.status);
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(c.ticketNo, style: ClaroType.readoutSm.copyWith(color: ClaroColors.onInkMuted)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: ClaroSpacing.sm, vertical: 2),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.14), borderRadius: ClaroRadius.pill),
                child: Text(c.status.label, style: ClaroType.caption.copyWith(color: color)),
              ),
            ],
          ),
          const SizedBox(height: ClaroSpacing.sm),
          Text(c.category.label, style: ClaroType.subtitle.copyWith(color: ClaroColors.onInk)),
          const SizedBox(height: 2),
          Text(
            c.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: ClaroType.body.copyWith(color: ClaroColors.onInkMuted),
          ),
          if (c.latestUpdate != null) ...[
            const SizedBox(height: ClaroSpacing.md),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(ClaroSpacing.md),
              decoration: BoxDecoration(color: ClaroColors.inkPanelHigh, borderRadius: ClaroRadius.md),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.support_agent_rounded, size: 18, color: ClaroColors.mint),
                  const SizedBox(width: ClaroSpacing.sm),
                  Expanded(
                    child: Text(c.latestUpdate!, style: ClaroType.caption.copyWith(color: ClaroColors.onInk)),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: ClaroSpacing.md),
          Text(
            'Raised ${formatRelativeTime(c.createdAt)} · Updated ${formatRelativeTime(c.updatedAt)}',
            style: ClaroType.caption.copyWith(color: ClaroColors.onInkMuted),
          ),
        ],
      ),
    );
  }
}
