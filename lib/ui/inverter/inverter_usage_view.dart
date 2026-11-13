import 'package:flutter/material.dart';

import '../../app/theme/claro_colors.dart';
import '../../app/theme/claro_dimens.dart';
import '../../app/theme/claro_palette.dart';
import '../../app/theme/claro_type.dart';
import '../../config/demo_users.dart';
import '../../core/models/smartnet_models.dart';
import '../common/ui_kit.dart';
import '../components/claro_line_chart.dart';

enum UsageRange { today, week, month }

class InverterUsageView extends StatefulWidget {
  const InverterUsageView({
    super.key,
    required this.config,
    required this.todayGraph,
    required this.history7Days,
    required this.monthHistory,
    required this.recentRecords,
    required this.isLoading,
    required this.error,
    required this.onRefresh,
  });

  final DemoUserConfig config;
  final SmartnetTodayGraph? todayGraph;
  final Smartnet7DaysHistory? history7Days;
  final SmartnetMonthHistory? monthHistory;
  final List<SmartnetCustomRangePoint> recentRecords;
  final bool isLoading;
  final String? error;
  final Future<void> Function() onRefresh;

  @override
  State<InverterUsageView> createState() => _InverterUsageViewState();
}

class _InverterUsageViewState extends State<InverterUsageView> {
  UsageRange _range = UsageRange.today;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        color: p.accentText,
        backgroundColor: p.panel,
        onRefresh: widget.onRefresh,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(ClaroSpacing.xl, ClaroSpacing.lg, ClaroSpacing.xl, kNavClearance),
          children: [
            Text('Energy', style: ClaroType.displayLg.copyWith(color: p.text, fontSize: 28)),
            Text('Solar inverter · sno ${widget.config.rmuSno}',
                style: ClaroType.caption.copyWith(color: p.textMuted)),
            const SizedBox(height: ClaroSpacing.xl),
            _buildRangeSelector(context),
            const SizedBox(height: ClaroSpacing.xl),
            if (widget.isLoading && widget.todayGraph == null && widget.history7Days == null)
              const SizedBox(height: 280, child: Center(child: CircularProgressIndicator()))
            else ...[
              _buildChartSection(context),
              const SizedBox(height: ClaroSpacing.xl),
              _buildSummaryTiles(context),
              const SizedBox(height: ClaroSpacing.md),
              _buildMonthlyReportCard(context),
              const SizedBox(height: ClaroSpacing.xl),
              _buildRecentReadingsTable(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRangeSelector(BuildContext context) {
    final p = context.palette;
    const labels = {
      UsageRange.today: 'Today',
      UsageRange.week: 'This week',
      UsageRange.month: 'This month',
    };

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: p.panel, borderRadius: ClaroRadius.pill),
      child: Row(
        children: [
          for (final range in UsageRange.values)
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => setState(() => _range = range),
                child: AnimatedContainer(
                  duration: ClaroMotion.fast,
                  padding: const EdgeInsets.symmetric(vertical: ClaroSpacing.sm),
                  decoration: BoxDecoration(
                    color: range == _range ? p.accentText : const Color(0x00000000),
                    borderRadius: ClaroRadius.pill,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    labels[range]!,
                    style: ClaroType.label.copyWith(
                      color: range == _range
                          ? (p.isDark ? ClaroColors.ink : ClaroColors.card)
                          : p.textMuted,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildChartSection(BuildContext context) {
    switch (_range) {
      case UsageRange.today:
        return _buildTodayChart(context);
      case UsageRange.week:
        return _buildWeekChart(context);
      case UsageRange.month:
        return _buildMonthChart(context);
    }
  }

  Widget _buildTodayChart(BuildContext context) {
    final p = context.palette;
    final tg = widget.todayGraph;
    final points = tg?.points ?? [];
    final chartPoints = points.map((pt) => pt.pvp).toList();

    // Find peak power and time
    double maxPvp = 0;
    String peakTime = '';
    for (final pt in points) {
      if ((pt.pvp ?? 0) > maxPvp) {
        maxPvp = pt.pvp!;
        peakTime = pt.label;
      }
    }

    final todayGen = tg?.todayGen;

    return Panel(
      padding: const EdgeInsets.all(ClaroSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Energy made today', style: ClaroType.label.copyWith(color: p.textMuted)),
          const SizedBox(height: ClaroSpacing.xs),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: Text(
                  todayGen == null ? '—' : formatOneDecimal(todayGen),
                  overflow: TextOverflow.ellipsis,
                  style: ClaroType.readoutXl.copyWith(color: p.text, fontSize: 38),
                ),
              ),
              const SizedBox(width: ClaroSpacing.sm),
              Text('kWh', style: ClaroType.subtitle.copyWith(color: p.textMuted)),
            ],
          ),
          if (maxPvp > 0) ...[
            const SizedBox(height: 2),
            Text(
              'Peak ${formatOneDecimal(maxPvp / 1000.0)} kW at $peakTime',
              style: ClaroType.caption.copyWith(color: p.accentText),
            ),
          ],
          const SizedBox(height: ClaroSpacing.xl),
          ClaroLineChart(
            points: chartPoints,
            xLabels: const ['6 AM', '9 AM', '12 PM', '3 PM', '6 PM'],
          ),
        ],
      ),
    );
  }

  Widget _buildWeekChart(BuildContext context) {
    final p = context.palette;
    final history = widget.history7Days;
    final points = history?.points ?? [];
    final total = points.map((pt) => pt.dkWh).whereType<double>().fold<double>(0, (a, b) => a + b);

    return Panel(
      padding: const EdgeInsets.all(ClaroSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Energy this week', style: ClaroType.label.copyWith(color: p.textMuted)),
          const SizedBox(height: ClaroSpacing.xs),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: Text(
                  points.isEmpty ? '—' : formatOneDecimal(total),
                  overflow: TextOverflow.ellipsis,
                  style: ClaroType.readoutXl.copyWith(color: p.text, fontSize: 38),
                ),
              ),
              const SizedBox(width: ClaroSpacing.sm),
              Text('kWh', style: ClaroType.subtitle.copyWith(color: p.textMuted)),
            ],
          ),
          const SizedBox(height: ClaroSpacing.xl),
          ClaroLineChart(
            points: points.map((pt) => pt.dkWh).toList(),
            xLabels: points.map((pt) => pt.label.split(',').last.trim()).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthChart(BuildContext context) {
    final p = context.palette;
    final history = widget.monthHistory;
    final points = history?.points ?? [];
    final total = points.map((pt) => pt.dkWh).whereType<double>().fold<double>(0, (a, b) => a + b);

    // Filter points up to current date (skip future empty days)
    final now = DateTime.now();
    final validPoints = points.where((pt) {
      if (pt.createdAt == null) return true;
      return !pt.createdAt!.isAfter(now);
    }).toList();

    final chartPoints = (validPoints.isNotEmpty ? validPoints : points).map((pt) => pt.dkWh).toList();
    final labels = (validPoints.isNotEmpty ? validPoints : points).where((pt) => pt.label.isNotEmpty).map((pt) => pt.label).toList();

    // Select ~5 distributed x-axis labels to prevent text overlapping
    final xLabels = <String>[];
    if (labels.isNotEmpty) {
      final count = labels.length;
      final indices = {0, count ~/ 4, count ~/ 2, (count * 3) ~/ 4, count - 1}.toList()..sort();
      for (final idx in indices) {
        if (idx < count) xLabels.add(labels[idx]);
      }
    }

    return Panel(
      padding: const EdgeInsets.all(ClaroSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Energy this month', style: ClaroType.label.copyWith(color: p.textMuted)),
          const SizedBox(height: ClaroSpacing.xs),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: Text(
                  points.isEmpty ? '—' : formatOneDecimal(total),
                  overflow: TextOverflow.ellipsis,
                  style: ClaroType.readoutXl.copyWith(color: p.text, fontSize: 38),
                ),
              ),
              const SizedBox(width: ClaroSpacing.sm),
              Text('kWh', style: ClaroType.subtitle.copyWith(color: p.textMuted)),
            ],
          ),
          const SizedBox(height: ClaroSpacing.xl),
          ClaroLineChart(
            points: chartPoints,
            xLabels: xLabels,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryTiles(BuildContext context) {
    final p = context.palette;
    final weekTotal = widget.history7Days?.points.map((pt) => pt.dkWh).whereType<double>().fold<double>(0, (a, b) => a + b);
    final monthTotal = widget.monthHistory?.points.map((pt) => pt.dkWh).whereType<double>().fold<double>(0, (a, b) => a + b);

    return Row(
      children: [
        Expanded(
          child: Panel(
            padding: const EdgeInsets.all(ClaroSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('This week', style: ClaroType.caption.copyWith(color: p.textMuted)),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(weekTotal == null ? '—' : formatOneDecimal(weekTotal), style: ClaroType.title.copyWith(color: p.text, fontWeight: FontWeight.bold, fontSize: 22)),
                    const SizedBox(width: 4),
                    Text('kWh', style: ClaroType.caption.copyWith(color: p.textMuted)),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: ClaroSpacing.md),
        Expanded(
          child: Panel(
            padding: const EdgeInsets.all(ClaroSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('This month', style: ClaroType.caption.copyWith(color: p.textMuted)),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(monthTotal == null ? '—' : formatOneDecimal(monthTotal), style: ClaroType.title.copyWith(color: p.text, fontWeight: FontWeight.bold, fontSize: 22)),
                    const SizedBox(width: 4),
                    Text('kWh', style: ClaroType.caption.copyWith(color: p.textMuted)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMonthlyReportCard(BuildContext context) {
    final p = context.palette;
    return Panel(
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: p.panelHigh, borderRadius: ClaroRadius.md),
            child: Icon(Icons.calendar_today_rounded, color: p.accentText, size: 20),
          ),
          const SizedBox(width: ClaroSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Monthly report', style: ClaroType.subtitle.copyWith(color: p.text, fontWeight: FontWeight.bold)),
                Text('Daily generation for November', style: ClaroType.caption.copyWith(color: p.textMuted)),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: p.textMuted),
        ],
      ),
    );
  }

  Widget _buildRecentReadingsTable(BuildContext context) {
    final p = context.palette;
    final records = widget.recentRecords;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'RECENT READINGS'),
        const SizedBox(height: ClaroSpacing.md),
        if (records.isEmpty)
          Panel(
            child: Text('No readings available for today yet.',
                style: ClaroType.body.copyWith(color: p.textMuted)),
          )
        else
          Panel(
            padding: const EdgeInsets.symmetric(horizontal: ClaroSpacing.lg, vertical: ClaroSpacing.md),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(child: Text('Time', style: ClaroType.caption.copyWith(color: p.textMuted))),
                    SizedBox(width: 70, child: Text('Solar', textAlign: TextAlign.right, style: ClaroType.caption.copyWith(color: p.textMuted))),
                    SizedBox(width: 70, child: Text('Grid', textAlign: TextAlign.right, style: ClaroType.caption.copyWith(color: p.textMuted))),
                    SizedBox(width: 50, child: Text('Status', textAlign: TextAlign.right, style: ClaroType.caption.copyWith(color: p.textMuted))),
                  ],
                ),
                Divider(height: 16, color: p.border),
                for (final r in records.take(6)) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            r.createdAt == null ? '—' : '${r.createdAt!.toLocal().hour > 12 ? r.createdAt!.toLocal().hour - 12 : (r.createdAt!.toLocal().hour == 0 ? 12 : r.createdAt!.toLocal().hour)}:${r.createdAt!.toLocal().minute.toString().padLeft(2, '0')} ${r.createdAt!.toLocal().hour >= 12 ? 'PM' : 'AM'}',
                            style: ClaroType.body.copyWith(color: p.text, fontWeight: FontWeight.bold),
                          ),
                        ),
                        SizedBox(
                          width: 70,
                          child: Text(
                            '${formatOneDecimal((r.pvp ?? 0) / 1000.0)} kW',
                            textAlign: TextAlign.right,
                            style: ClaroType.caption.copyWith(color: p.text),
                          ),
                        ),
                        SizedBox(
                          width: 70,
                          child: Text(
                            '${r.gv?.round() ?? 0} V',
                            textAlign: TextAlign.right,
                            style: ClaroType.caption.copyWith(color: p.text),
                          ),
                        ),
                        SizedBox(
                          width: 50,
                          child: Text(
                            r.activeFaults.isEmpty ? 'OK' : 'FAULT',
                            textAlign: TextAlign.right,
                            style: ClaroType.caption.copyWith(
                              color: r.activeFaults.isEmpty ? p.accentText : ClaroColors.fault,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        const SizedBox(height: ClaroSpacing.sm),
        Center(
          child: Text('New reading about every 10 minutes', style: ClaroType.caption.copyWith(color: p.textMuted, fontSize: 11)),
        ),
      ],
    );
  }
}
