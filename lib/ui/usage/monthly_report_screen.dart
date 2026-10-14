import 'package:flutter/material.dart';

import '../../app/theme/claro_dimens.dart';
import '../../app/theme/claro_palette.dart';
import '../../app/theme/claro_type.dart';
import '../../core/api/api_exception.dart';
import '../../core/api/claro_pulse_api.dart';
import '../../core/api/models/device_models.dart';
import '../../core/api/models/pump_models.dart';
import '../common/ui_kit.dart';
import '../home/home_dashboard.dart' show deviceTitle;
import 'usage_tab.dart' show WaterBarChart;

const _monthNames = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

/// This month at a glance: water, run time, energy, money saved and the best
/// day. Sharing and downloading are shown but not wired up yet.
class MonthlyReportScreen extends StatefulWidget {
  const MonthlyReportScreen({super.key, required this.device, required this.api, required this.onBack});

  final MyDevice device;
  final ClaroPulseApi api;
  final VoidCallback onBack;

  @override
  State<MonthlyReportScreen> createState() => _MonthlyReportScreenState();
}

class _MonthlyReportScreenState extends State<MonthlyReportScreen> {
  MonthlyReport? _report;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final report = await widget.api.getMonthlyReport(widget.device.deviceId);
      if (mounted) setState(() => _report = report);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  void _comingSoon() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Sharing reports is coming soon')));
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final report = _report;
    return Scaffold(
      backgroundColor: p.bg,
      body: SafeArea(
        child: Column(
          children: [
            BackHeader(title: 'Monthly report', onBack: widget.onBack),
            Expanded(
              child: report == null
                  ? (_error == null
                      ? Center(child: CircularProgressIndicator(color: p.accentText))
                      : Center(
                          child: MessageState(
                            icon: Icons.description_outlined,
                            title: "Report isn't available",
                            message: _error!,
                            actionLabel: 'Try again',
                            onAction: _load,
                            isError: true,
                          ),
                        ))
                  : _content(context, report),
            ),
          ],
        ),
      ),
    );
  }

  Widget _content(BuildContext context, MonthlyReport r) {
    final p = context.palette;
    final month = DateTime.tryParse(r.month);
    final monthName = month == null ? '' : '${_monthNames[month.month - 1]} ${month.year}';
    final best = DateTime.tryParse(r.bestDay);
    return ListView(
      padding: const EdgeInsets.fromLTRB(ClaroSpacing.xl, ClaroSpacing.sm, ClaroSpacing.xl, ClaroSpacing.xxl),
      children: [
        Text(monthName, style: ClaroType.displayLg.copyWith(color: p.text, fontSize: 26)),
        Text(
          '${deviceTitle(widget.device)} · ${widget.device.deviceUid} · so far this month',
          style: ClaroType.caption.copyWith(color: p.textMuted),
        ),
        const SizedBox(height: ClaroSpacing.xl),
        Panel(
          padding: const EdgeInsets.all(ClaroSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Total water', style: ClaroType.label.copyWith(color: p.textMuted)),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Flexible(
                    child: Text(
                      formatWhole(r.waterLiters),
                      overflow: TextOverflow.ellipsis,
                      style: ClaroType.readoutXl.copyWith(color: p.text, fontSize: 38),
                    ),
                  ),
                  const SizedBox(width: ClaroSpacing.sm),
                  Text('litres', style: ClaroType.subtitle.copyWith(color: p.textMuted)),
                ],
              ),
              Text(
                'Pumped on ${r.daysRun} day${r.daysRun == 1 ? '' : 's'}',
                style: ClaroType.caption.copyWith(color: p.accentText),
              ),
              const SizedBox(height: ClaroSpacing.xl),
              WaterBarChart(values: r.dailyWaterLiters, labels: const [], height: 120),
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
                value: formatOneDecimal(r.runHours),
                unit: 'hrs',
              ),
            ),
            const SizedBox(width: ClaroSpacing.md),
            Expanded(
              child: StatTile(
                icon: Icons.bolt_rounded,
                label: 'Energy used',
                value: formatOneDecimal(r.energyKwh),
                unit: 'kWh',
              ),
            ),
          ],
        ),
        const SizedBox(height: ClaroSpacing.md),
        TintedPanel(
          tint: p.accent,
          child: Row(
            children: [
              const IconTile(icon: Icons.savings_rounded, size: 48),
              const SizedBox(width: ClaroSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Saved this month', style: ClaroType.caption.copyWith(color: p.textMuted)),
                    Text(
                      '₹${formatWhole(r.savingsRupees)}',
                      style: ClaroType.readoutLg.copyWith(color: p.text, fontSize: 26),
                    ),
                    Text(
                      'Compared with running a diesel pump',
                      style: ClaroType.caption.copyWith(color: p.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: ClaroSpacing.md),
        Panel(
          child: Row(
            children: [
              const IconTile(icon: Icons.emoji_events_rounded),
              const SizedBox(width: ClaroSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Best day', style: ClaroType.caption.copyWith(color: p.textMuted)),
                    Text(
                      best == null ? dash : '${best.day} ${_monthNames[best.month - 1]}',
                      style: ClaroType.subtitle.copyWith(color: p.text, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              Text('${formatWhole(r.bestDayLiters)} L', style: ClaroType.readout.copyWith(color: p.text)),
            ],
          ),
        ),
        const SizedBox(height: ClaroSpacing.xl),
        AccentButton(text: 'Share report', icon: Icons.share_rounded, onPressed: _comingSoon),
        const SizedBox(height: ClaroSpacing.sm),
        Center(
          child: TextButton.icon(
            onPressed: _comingSoon,
            icon: Icon(Icons.download_rounded, color: p.accentText, size: 20),
            label: Text('Download as PDF', style: ClaroType.subtitle.copyWith(color: p.accentText)),
          ),
        ),
      ],
    );
  }
}
