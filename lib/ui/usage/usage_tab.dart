import 'package:flutter/material.dart';

import '../../app/theme/claro_dimens.dart';
import '../../app/theme/claro_palette.dart';
import '../../app/theme/claro_type.dart';
import '../../core/api/api_exception.dart';
import '../../core/api/claro_pulse_api.dart';
import '../../core/api/models/device_models.dart';
import '../../core/api/models/pump_models.dart';
import '../common/ui_kit.dart';
import '../devices/device_kind.dart';
import '../home/home_cards.dart';
import '../home/home_dashboard.dart' show deviceTitle;

/// The Usage tab: how much water the pump moved today, this week, this month,
/// its recent runs, and the monthly report. Water first, in litres; run time
/// and energy are supporting numbers.
class UsageTab extends StatefulWidget {
  const UsageTab({
    super.key,
    required this.device,
    required this.api,
    required this.onAddDevice,
    required this.onOpenReport,
  });

  final MyDevice? device;
  final ClaroPulseApi api;
  final VoidCallback onAddDevice;
  final VoidCallback onOpenReport;

  @override
  State<UsageTab> createState() => _UsageTabState();
}

class _UsageTabState extends State<UsageTab> {
  ActivityRange _range = ActivityRange.day;
  DeviceActivity? _activity;
  String? _error;
  bool _loading = false;
  List<PumpRun>? _runs;

  bool get _isPump {
    final device = widget.device;
    return device != null && DeviceKind.from(device.kind) == DeviceKind.pump;
  }

  @override
  void initState() {
    super.initState();
    _load();
    _loadRuns();
  }

  Future<void> _load() async {
    final device = widget.device;
    if (device == null || !_isPump) return;
    final range = _range;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final activity = await widget.api.getDeviceActivity(device.deviceId, range);
      if (!mounted || range != _range) return;
      setState(() {
        _activity = activity;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  Future<void> _loadRuns() async {
    final device = widget.device;
    if (device == null || !_isPump) return;
    try {
      final runs = await widget.api.listRecentRuns(device.deviceId);
      if (mounted) setState(() => _runs = runs);
    } on ApiException {
      // The section simply doesn't show.
    }
  }

  void _select(ActivityRange range) {
    if (range == _range) return;
    setState(() => _range = range);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final device = widget.device;
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(ClaroSpacing.xl, ClaroSpacing.lg, ClaroSpacing.xl, ClaroSpacing.xxl),
        children: [
          PageTitle(
            title: 'Water usage',
            subtitle: device == null ? null : '${deviceTitle(device)} · ${device.deviceUid}',
          ),
          const SizedBox(height: ClaroSpacing.xl),
          if (device == null)
            MessageState(
              icon: Icons.water_drop_outlined,
              title: 'No pump added yet',
              message: 'Add your pump to see how much water it moves.',
              actionLabel: 'Add a device',
              onAction: widget.onAddDevice,
            )
          else if (!_isPump)
            const MessageState(
              icon: Icons.hourglass_top_rounded,
              title: 'Coming soon',
              message: 'Usage history for inverters is coming soon.',
            )
          else ...[
            _RangeSelector(selected: _range, onSelect: _select),
            const SizedBox(height: ClaroSpacing.xl),
            ..._content(context),
            const SizedBox(height: ClaroSpacing.xl),
            _ReportLink(onTap: widget.onOpenReport),
            if (_runs != null && _runs!.isNotEmpty) ...[
              const SizedBox(height: ClaroSpacing.xl),
              const SectionHeader(title: 'Recent runs'),
              const SizedBox(height: ClaroSpacing.md),
              RecentRunsList(runs: _runs!),
            ],
          ],
        ],
      ),
    );
  }

  List<Widget> _content(BuildContext context) {
    final p = context.palette;
    final activity = _activity;
    if (activity == null && _loading) {
      return [SizedBox(height: 280, child: Center(child: CircularProgressIndicator(color: p.accentText)))];
    }
    if (activity == null) {
      return [
        MessageState(
          icon: Icons.sync_problem_rounded,
          title: "Couldn't load usage",
          message: _error ?? 'Something went wrong.',
          actionLabel: 'Try again',
          onAction: _load,
          isError: true,
        ),
      ];
    }

    final water = activity.points.map((pt) => pt.waterLiters).toList();
    final reported = water.whereType<double>().toList();
    final total = reported.fold<double>(0, (a, b) => a + b);
    double sumOf(double? Function(ActivityPoint) pick) =>
        activity.points.map(pick).whereType<double>().fold<double>(0, (a, b) => a + b);
    final average = reported.isEmpty ? null : total / reported.length;

    final caption = switch (_range) {
      ActivityRange.day => 'So far today',
      _ => 'Average ${formatWhole(average)} litres a day',
    };

    return [
      Panel(
        padding: const EdgeInsets.all(ClaroSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total water', style: ClaroType.label.copyWith(color: p.textMuted)),
            const SizedBox(height: ClaroSpacing.xs),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Flexible(
                  child: Text(
                    reported.isEmpty ? dash : formatWhole(total),
                    overflow: TextOverflow.ellipsis,
                    style: ClaroType.readoutXl.copyWith(color: p.text, fontSize: 38),
                  ),
                ),
                const SizedBox(width: ClaroSpacing.sm),
                Text('litres', style: ClaroType.subtitle.copyWith(color: p.textMuted)),
              ],
            ),
            Text(caption, style: ClaroType.caption.copyWith(color: p.accentText)),
            const SizedBox(height: ClaroSpacing.xl),
            WaterBarChart(values: water, labels: _labels(activity.points)),
          ],
        ),
      ),
      const SizedBox(height: ClaroSpacing.md),
      Row(
        children: [
          Expanded(
            child: StatTile(
              icon: Icons.schedule_rounded,
              label: 'Run time',
              value: formatOneDecimal(sumOf((pt) => pt.runHours)),
              unit: 'hrs',
            ),
          ),
          const SizedBox(width: ClaroSpacing.md),
          Expanded(
            child: StatTile(
              icon: Icons.bolt_rounded,
              label: 'Energy used',
              value: formatOneDecimal(sumOf((pt) => pt.energyKwh)),
              unit: 'kWh',
            ),
          ),
        ],
      ),
    ];
  }

  List<String> _labels(List<ActivityPoint> points) {
    if (points.isEmpty) return const [];
    final indices = {0, points.length ~/ 2, points.length - 1}.toList()..sort();
    return [
      for (final i in indices)
        () {
          final t = DateTime.tryParse(points[i].bucketStart)?.toLocal();
          if (t == null) return '';
          return switch (_range) {
            ActivityRange.day => formatHour(t),
            ActivityRange.week => formatWeekday(t),
            ActivityRange.month => formatDayMonth(t),
          };
        }(),
    ];
  }
}

class _ReportLink extends StatelessWidget {
  const _ReportLink({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Panel(
      onTap: onTap,
      child: Row(
        children: [
          const IconTile(icon: Icons.description_outlined),
          const SizedBox(width: ClaroSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Monthly report', style: ClaroType.subtitle.copyWith(color: p.text)),
                Text(
                  'Water, run time and savings for this month',
                  style: ClaroType.caption.copyWith(color: p.textMuted),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: p.textMuted),
        ],
      ),
    );
  }
}

class _RangeSelector extends StatelessWidget {
  const _RangeSelector({required this.selected, required this.onSelect});

  final ActivityRange selected;
  final ValueChanged<ActivityRange> onSelect;

  static const _labels = {
    ActivityRange.day: 'Today',
    ActivityRange.week: 'This week',
    ActivityRange.month: 'This month',
  };

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: p.panel,
        borderRadius: ClaroRadius.pill,
        border: Border.all(color: p.border),
      ),
      child: Row(
        children: [
          for (final range in ActivityRange.values)
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onSelect(range),
                child: AnimatedContainer(
                  duration: ClaroMotion.fast,
                  padding: const EdgeInsets.symmetric(vertical: ClaroSpacing.sm),
                  decoration: BoxDecoration(
                    color: range == selected ? p.accent : const Color(0x00000000),
                    borderRadius: ClaroRadius.pill,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _labels[range]!,
                    style: ClaroType.label.copyWith(color: range == selected ? p.onAccent : p.textMuted),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Rounded bars, one per period. A period with no report shows a small grey
/// dot on the baseline: a gap, never a fake zero.
class WaterBarChart extends StatelessWidget {
  const WaterBarChart({super.key, required this.values, required this.labels, this.height = 170});

  final List<double?> values;
  final List<String> labels;
  final double height;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(
      children: [
        SizedBox(
          height: height,
          width: double.infinity,
          child: TweenAnimationBuilder<double>(
            key: ValueKey(values.length),
            tween: Tween(begin: 0, end: 1),
            duration: ClaroMotion.slow,
            curve: Curves.easeOutCubic,
            builder: (context, grow, _) => CustomPaint(
              painter: _BarPainter(
                values: values,
                grow: grow,
                // Mint bars on dark; the deeper green on light, where mint is too pale.
                barColor: p.isDark ? p.accent : p.accentText,
                gapColor: p.border,
              ),
            ),
          ),
        ),
        if (labels.isNotEmpty) ...[
          const SizedBox(height: ClaroSpacing.sm),
          Row(
            children: [
              for (var i = 0; i < labels.length; i++)
                Expanded(
                  child: Text(
                    labels[i],
                    textAlign: i == 0
                        ? TextAlign.start
                        : i == labels.length - 1
                            ? TextAlign.end
                            : TextAlign.center,
                    style: ClaroType.caption.copyWith(color: p.textMuted),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _BarPainter extends CustomPainter {
  _BarPainter({required this.values, required this.grow, required this.barColor, required this.gapColor});

  final List<double?> values;
  final double grow;
  final Color barColor;
  final Color gapColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    final maxValue = values.whereType<double>().fold<double>(0, (a, b) => a > b ? a : b);
    final slot = size.width / values.length;
    final barWidth = (slot * 0.62).clamp(2.0, 22.0);
    final bar = Paint()..color = barColor;
    final gap = Paint()..color = gapColor;

    for (var i = 0; i < values.length; i++) {
      final x = slot * i + (slot - barWidth) / 2;
      final v = values[i];
      if (v == null) {
        canvas.drawCircle(Offset(x + barWidth / 2, size.height - 2), 2, gap);
        continue;
      }
      final h = maxValue <= 0 ? 0.0 : (v / maxValue) * (size.height - 4) * grow;
      if (h <= 0) continue;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, size.height - h, barWidth, h),
          Radius.circular(barWidth / 2 > 6 ? 6 : barWidth / 2),
        ),
        bar,
      );
    }
  }

  @override
  bool shouldRepaint(_BarPainter old) =>
      old.values != values || old.grow != grow || old.barColor != barColor || old.gapColor != gapColor;
}
