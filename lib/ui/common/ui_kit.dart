import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/theme/claro_dimens.dart';
import '../../app/theme/claro_palette.dart';
import '../../app/theme/claro_type.dart';

// Small shared pieces for the main screens. Colours come from `context.palette`,
// so everything works in both the light and the dark theme.

/// A rounded card. Tappable when [onTap] is given.
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
    final p = context.palette;
    return Material(
      color: color ?? p.panel,
      borderRadius: radius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        splashColor: p.accent.withValues(alpha: 0.10),
        highlightColor: p.accent.withValues(alpha: 0.05),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(color: borderColor ?? p.border),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// A tinted card for warnings, faults and highlights.
class TintedPanel extends StatelessWidget {
  const TintedPanel({super.key, required this.tint, required this.child, this.onTap});

  final Color tint;
  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Panel(
      onTap: onTap,
      color: tint.withValues(alpha: context.palette.isDark ? 0.10 : 0.12),
      borderColor: tint.withValues(alpha: 0.4),
      child: child,
    );
  }
}

/// A section title, with an optional action on the right.
class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.actionLabel, this.onAction});

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Row(
      children: [
        Expanded(
          child: Text(
            title.toUpperCase(),
            style: ClaroType.caption.copyWith(color: p.textMuted, letterSpacing: 1.2, fontWeight: FontWeight.w600),
          ),
        ),
        if (actionLabel != null)
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onAction,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: ClaroSpacing.xs),
              child: Text(actionLabel!, style: ClaroType.label.copyWith(color: p.accentText)),
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

  /// Green icon and ring, e.g. Bluetooth connected.
  final bool active;
  final double size;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
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
                  color: p.panel,
                  border: Border.all(color: active ? p.accentText.withValues(alpha: 0.6) : p.border),
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: size * 0.45, color: active ? p.accentText : p.text),
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
                      color: p.fault,
                      borderRadius: ClaroRadius.pill,
                      border: Border.all(color: p.bg, width: 2),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      badgeCount > 9 ? '9+' : '$badgeCount',
                      style: ClaroType.caption.copyWith(color: const Color(0xFFFFFFFF), fontSize: 10, height: 1),
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
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: ClaroSpacing.md, vertical: 6),
      decoration: BoxDecoration(
        // A solid backing so the label stays readable over the photo.
        color: Color.alphaBlend(widget.color.withValues(alpha: 0.16), p.panel),
        borderRadius: ClaroRadius.pill,
        border: Border.all(color: widget.color.withValues(alpha: 0.4)),
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

/// A small icon tile used at the start of cards and rows.
class IconTile extends StatelessWidget {
  const IconTile({super.key, required this.icon, this.color, this.size = 40});

  final IconData icon;
  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final c = color ?? p.accentText;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: ClaroRadius.md,
      ),
      alignment: Alignment.center,
      child: Icon(icon, size: size * 0.5, color: c),
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
    final p = context.palette;
    final hasValue = value != dash;
    return Panel(
      padding: const EdgeInsets.all(ClaroSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconTile(icon: icon, size: 32),
          const SizedBox(height: ClaroSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: Text(
                  value,
                  overflow: TextOverflow.ellipsis,
                  style: ClaroType.readoutLg.copyWith(color: hasValue ? p.text : p.textMuted, fontSize: 22),
                ),
              ),
              const SizedBox(width: 4),
              Flexible(child: Text(unit, style: ClaroType.caption.copyWith(color: p.textMuted))),
            ],
          ),
          const SizedBox(height: 2),
          Text(label, style: ClaroType.caption.copyWith(color: p.textMuted)),
        ],
      ),
    );
  }
}

/// A small label + value pair, used inside cards.
class MiniStat extends StatelessWidget {
  const MiniStat({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: ClaroType.caption.copyWith(color: p.textMuted)),
        const SizedBox(height: 2),
        Text(value, style: ClaroType.readout.copyWith(color: p.text)),
      ],
    );
  }
}

/// A page title bar with a round back button, for full-screen pages.
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
          Expanded(
            child: Text(title, style: ClaroType.title.copyWith(color: context.palette.text)),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// A big page title with an optional subtitle, used at the top of each tab.
class PageTitle extends StatelessWidget {
  const PageTitle({super.key, required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: ClaroType.displayLg.copyWith(color: p.text, fontSize: 28)),
        if (subtitle != null) Text(subtitle!, style: ClaroType.caption.copyWith(color: p.textMuted)),
      ],
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
    final p = context.palette;
    final tint = isError ? p.faultText : p.accentText;
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
          Text(title, textAlign: TextAlign.center, style: ClaroType.title.copyWith(color: p.text)),
          const SizedBox(height: ClaroSpacing.xs),
          Text(message, textAlign: TextAlign.center, style: ClaroType.body.copyWith(color: p.textMuted)),
          if (actionLabel != null) ...[
            const SizedBox(height: ClaroSpacing.lg),
            TextButton(
              onPressed: onAction,
              child: Text(actionLabel!, style: ClaroType.subtitle.copyWith(color: p.accentText)),
            ),
          ],
        ],
      ),
    );
  }
}

/// The primary action button for the main screens: a mint fill with dark text
/// in both themes. Disabled = a faint fill with muted text.
class AccentButton extends StatelessWidget {
  const AccentButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.enabled = true,
    this.loading = false,
    this.icon,
  });

  final String text;
  final VoidCallback onPressed;
  final bool enabled;
  final bool loading;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final active = enabled && !loading;
    return Semantics(
      button: true,
      enabled: active,
      child: Material(
        color: active ? p.accent : p.panelHigh,
        borderRadius: ClaroRadius.md,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: active ? onPressed : null,
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: Center(
              child: loading
                  ? SizedBox.square(
                      dimension: 22,
                      child: CircularProgressIndicator(strokeWidth: 2, color: p.onAccent),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (icon != null) ...[
                          Icon(icon, size: 20, color: active ? p.onAccent : p.textMuted),
                          const SizedBox(width: ClaroSpacing.sm),
                        ],
                        Flexible(
                          child: Text(
                            text,
                            overflow: TextOverflow.ellipsis,
                            style: ClaroType.subtitle.copyWith(
                              color: active ? p.onAccent : p.textMuted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The small grey handle at the top of bottom sheets.
class SheetHandle extends StatelessWidget {
  const SheetHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(color: context.palette.border, borderRadius: ClaroRadius.pill),
      ),
    );
  }
}

/// Space to leave at the bottom of scrolling tabs, so the floating tab bar
/// never covers the last item.
const double kNavClearance = 120;

/// A number that counts up (or down) to its new value: changes feel live.
/// Null shows a dash.
class CountUpText extends StatelessWidget {
  const CountUpText({
    super.key,
    required this.value,
    required this.format,
    required this.style,
    this.duration = const Duration(milliseconds: 700),
  });

  final double? value;
  final String Function(double) format;
  final TextStyle style;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final v = value;
    if (v == null) return Text(dash, style: style);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: v),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, shown, _) => Text(format(shown), overflow: TextOverflow.ellipsis, style: style),
    );
  }
}

/// A thin circular progress ring with a label in the middle.
class ProgressRing extends StatelessWidget {
  const ProgressRing({super.key, required this.fraction, required this.label, this.size = 64});

  /// 0..1 (values above 1 show a full ring).
  final double fraction;
  final String label;
  final double size;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return SizedBox.square(
      dimension: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: fraction.clamp(0.0, 1.0)),
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeOutCubic,
        builder: (context, f, _) => CustomPaint(
          painter: _RingPainter(fraction: f, track: p.border, fill: p.accent),
          child: Center(
            child: Text(label, style: ClaroType.caption.copyWith(color: p.text, fontWeight: FontWeight.w600)),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.fraction, required this.track, required this.fill});

  final double fraction;
  final Color track;
  final Color fill;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 6.0;
    final rect = Rect.fromCircle(center: size.center(Offset.zero), radius: size.shortestSide / 2 - stroke / 2);
    Paint paint(Color c) => Paint()
      ..color = c
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, 0, math.pi * 2, false, paint(track));
    if (fraction > 0) canvas.drawArc(rect, -math.pi / 2, math.pi * 2 * fraction, false, paint(fill));
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.fraction != fraction || old.fill != fill || old.track != track;
}

/// One item of the compact stats strip.
class StripStat {
  const StripStat({required this.icon, required this.value, required this.unit, required this.label});

  final IconData icon;
  final String value;
  final String unit;
  final String label;
}

/// Four numbers in one slim card, like a vehicle dashboard.
class StatsStrip extends StatelessWidget {
  const StatsStrip({super.key, required this.items});

  final List<StripStat> items;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Panel(
      padding: const EdgeInsets.symmetric(vertical: ClaroSpacing.lg, horizontal: ClaroSpacing.sm),
      child: Row(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) Container(width: 1, height: 44, color: p.border),
            Expanded(
              child: Column(
                children: [
                  Icon(items[i].icon, size: 18, color: p.accentText),
                  const SizedBox(height: ClaroSpacing.xs),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: items[i].value,
                          style: ClaroType.readout.copyWith(
                            color: items[i].value == dash ? p.textMuted : p.text,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        TextSpan(text: ' ${items[i].unit}', style: ClaroType.caption.copyWith(color: p.textMuted)),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    items[i].label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: ClaroType.caption.copyWith(color: p.textMuted, fontSize: 10),
                  ),
                ],
              ),
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

/// "9:42 AM", in local time.
String formatClock(DateTime t) {
  final local = t.isUtc ? t.toLocal() : t;
  final h = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final m = local.minute.toString().padLeft(2, '0');
  return '$h:$m ${local.hour < 12 ? 'AM' : 'PM'}';
}

/// "Today", "Yesterday", or "14 Oct", in local time.
String formatDayName(DateTime t, [DateTime? now]) {
  final local = t.isUtc ? t.toLocal() : t;
  final today = now ?? DateTime.now();
  final day = DateTime(local.year, local.month, local.day);
  final todayDate = DateTime(today.year, today.month, today.day);
  final diff = todayDate.difference(day).inDays;
  if (diff == 0) return 'Today';
  if (diff == 1) return 'Yesterday';
  return formatDayMonth(local);
}

/// "3 h 12 min", "45 min", "6 h".
String formatDuration(Duration d) {
  final hours = d.inHours;
  final minutes = d.inMinutes % 60;
  if (hours == 0) return '$minutes min';
  if (minutes == 0) return '$hours h';
  return '$hours h $minutes min';
}
