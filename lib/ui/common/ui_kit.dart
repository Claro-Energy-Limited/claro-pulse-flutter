import 'package:flutter/material.dart';

import '../../app/theme/claro_colors.dart';
import '../../app/theme/claro_dimens.dart';
import '../../app/theme/claro_type.dart';

// Small shared pieces for the redesigned screens. Everything uses the design
// tokens; nothing here hardcodes a colour or size the tokens already define.

/// A rounded dark card. Tappable when [onTap] is given.
class Panel extends StatelessWidget {
  const Panel({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(ClaroSpacing.lg),
    this.color,
    this.borderColor,
    this.radius = ClaroRadius.lg,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final Color? borderColor;
  final BorderRadius radius;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color ?? ClaroColors.inkPanel,
      borderRadius: radius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        splashColor: ClaroColors.mint.withValues(alpha: 0.08),
        highlightColor: ClaroColors.mint.withValues(alpha: 0.04),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(color: borderColor ?? ClaroColors.borderDark),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// A screen or section title, with an optional action on the right.
class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.actionLabel, this.onAction});

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(title, style: ClaroType.subtitle.copyWith(color: ClaroColors.onInk))),
        if (actionLabel != null)
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onAction,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: ClaroSpacing.xs),
              child: Text(actionLabel!, style: ClaroType.label.copyWith(color: ClaroColors.mint)),
            ),
          ),
      ],
    );
  }
}

/// A round icon button, optionally with a count badge (e.g. unread alerts).
class CircleIconButton extends StatelessWidget {
  const CircleIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.badgeCount = 0,
    this.active = false,
    this.size = 44,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final int badgeCount;

  /// Mint icon and ring, e.g. Bluetooth connected.
  final bool active;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPressed,
        child: SizedBox.square(
          dimension: size,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: ClaroColors.inkPanel,
                  border: Border.all(
                    color: active ? ClaroColors.mint.withValues(alpha: 0.6) : ClaroColors.borderDark,
                  ),
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: size * 0.45, color: active ? ClaroColors.mint : ClaroColors.onInk),
              ),
              if (badgeCount > 0)
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    constraints: const BoxConstraints(minWidth: 18),
                    height: 18,
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    decoration: BoxDecoration(
                      color: ClaroColors.fault,
                      borderRadius: ClaroRadius.pill,
                      border: Border.all(color: ClaroColors.ink, width: 2),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      badgeCount > 9 ? '9+' : '$badgeCount',
                      style: ClaroType.caption.copyWith(color: ClaroColors.onInk, fontSize: 10, height: 1),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A pill-shaped status label with a dot. The dot pulses when [pulse] is true,
/// which is used only for a running pump: motion means "live".
class StatusChip extends StatefulWidget {
  const StatusChip({super.key, required this.label, required this.color, this.pulse = false});

  final String label;
  final Color color;
  final bool pulse;

  @override
  State<StatusChip> createState() => _StatusChipState();
}

class _StatusChipState extends State<StatusChip> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(StatusChip old) {
    super.didUpdateWidget(old);
    _sync();
  }

  void _sync() {
    if (widget.pulse) {
      if (!_controller.isAnimating) _controller.repeat(reverse: true);
    } else {
      _controller
        ..stop()
        ..value = 1;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: ClaroSpacing.md, vertical: 6),
      decoration: BoxDecoration(
        color: widget.color.withValues(alpha: 0.14),
        borderRadius: ClaroRadius.pill,
        border: Border.all(color: widget.color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) => Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color.withValues(alpha: widget.pulse ? 0.4 + 0.6 * _controller.value : 1),
              ),
            ),
          ),
          const SizedBox(width: ClaroSpacing.sm),
          Text(widget.label, style: ClaroType.label.copyWith(color: widget.color)),
        ],
      ),
    );
  }
}

/// One small metric card: icon, label, and a number with its unit.
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
  });

  final IconData icon;
  final String label;
  final String value;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final hasValue = value != '—';
    return Panel(
      padding: const EdgeInsets.all(ClaroSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: ClaroColors.mint.withValues(alpha: 0.12),
              borderRadius: ClaroRadius.sm,
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 18, color: ClaroColors.mint),
          ),
          const SizedBox(height: ClaroSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: Text(
                  value,
                  overflow: TextOverflow.ellipsis,
                  style: ClaroType.readoutLg.copyWith(
                    color: hasValue ? ClaroColors.onInk : ClaroColors.onInkMuted,
                    fontSize: 22,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Text(unit, style: ClaroType.caption.copyWith(color: ClaroColors.onInkMuted)),
            ],
          ),
          const SizedBox(height: 2),
          Text(label, style: ClaroType.caption.copyWith(color: ClaroColors.onInkMuted)),
        ],
      ),
    );
  }
}

/// A screen title bar with a round back button, for full-screen pages.
class BackHeader extends StatelessWidget {
  const BackHeader({super.key, required this.title, required this.onBack, this.trailing});

  final String title;
  final VoidCallback onBack;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(ClaroSpacing.lg, ClaroSpacing.md, ClaroSpacing.lg, ClaroSpacing.md),
      child: Row(
        children: [
          CircleIconButton(icon: Icons.arrow_back_rounded, tooltip: 'Back', onPressed: onBack, size: 40),
          const SizedBox(width: ClaroSpacing.md),
          Expanded(child: Text(title, style: ClaroType.title.copyWith(color: ClaroColors.onInk))),
          ?trailing,
        ],
      ),
    );
  }
}

/// A centred message with an optional action: empty and error states.
class MessageState extends StatelessWidget {
  const MessageState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.isError = false,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final tint = isError ? ClaroColors.fault : ClaroColors.mint;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: ClaroSpacing.xxl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(shape: BoxShape.circle, color: tint.withValues(alpha: 0.12)),
            child: Icon(icon, color: tint, size: 28),
          ),
          const SizedBox(height: ClaroSpacing.lg),
          Text(title, textAlign: TextAlign.center, style: ClaroType.title.copyWith(color: ClaroColors.onInk)),
          const SizedBox(height: ClaroSpacing.xs),
          Text(
            message,
            textAlign: TextAlign.center,
            style: ClaroType.body.copyWith(color: ClaroColors.onInkMuted),
          ),
          if (actionLabel != null) ...[
            const SizedBox(height: ClaroSpacing.lg),
            TextButton(
              onPressed: onAction,
              child: Text(actionLabel!, style: ClaroType.subtitle.copyWith(color: ClaroColors.mint)),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Formatting ─────────────────────────────────────────────────────────────

const String dash = '—';

/// 42000 → "42,000". Null → "—".
String formatWhole(double? value) {
  if (value == null) return dash;
  final digits = value.round().abs().toString();
  final buffer = StringBuffer(value < 0 ? '-' : '');
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
    buffer.write(digits[i]);
  }
  return buffer.toString();
}

/// 5.24 → "5.2". Null → "—".
String formatOneDecimal(double? value) => value == null ? dash : value.toStringAsFixed(1);

const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

/// "2026-03-14" or a full ISO timestamp → "14 Mar 2026". Unparseable → as given.
String formatDate(String iso) {
  final date = DateTime.tryParse(iso);
  if (date == null) return iso;
  final d = date.isUtc ? date.toLocal() : date;
  return '${d.day} ${_months[d.month - 1]} ${d.year}';
}

/// Short chart labels, in local time.
String formatHour(DateTime t) {
  final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
  return '$h ${t.hour < 12 ? 'AM' : 'PM'}';
}

String formatWeekday(DateTime t) => _weekdays[t.weekday - 1];

String formatDayMonth(DateTime t) => '${t.day} ${_months[t.month - 1]}';

/// "Good morning" / "Good afternoon" / "Good evening".
String greeting([DateTime? now]) {
  final hour = (now ?? DateTime.now()).hour;
  if (hour < 12) return 'Good morning';
  if (hour < 17) return 'Good afternoon';
  return 'Good evening';
}
