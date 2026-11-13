import 'package:flutter/material.dart';

import '../../app/theme/claro_colors.dart';
import '../../app/theme/claro_dimens.dart';
import '../../app/theme/claro_palette.dart';
import '../../app/theme/claro_type.dart';
import '../../config/demo_users.dart';
import '../../core/classifier/inverter_classifier.dart';
import '../../core/models/smartnet_models.dart';
import '../../core/util/relative_time.dart';
import '../common/ui_kit.dart';
import '../components/claro_line_chart.dart';
import '../components/claro_primary_button.dart';
import 'inverter_graphic.dart';

class InverterHomeView extends StatefulWidget {
  const InverterHomeView({
    super.key,
    required this.config,
    required this.latest,
    required this.classification,
    required this.todayGraph,
    required this.history7Days,
    required this.isLoading,
    required this.error,
    required this.onRefresh,
    required this.onOpenDetails,
    required this.onOpenAlerts,
    required this.onOpenComplaints,
    required this.unreadAlerts,
  });

  final DemoUserConfig config;
  final SmartnetLatestReading? latest;
  final InverterClassification classification;
  final SmartnetTodayGraph? todayGraph;
  final Smartnet7DaysHistory? history7Days;
  final bool isLoading;
  final String? error;
  final Future<void> Function() onRefresh;
  final VoidCallback onOpenDetails;
  final VoidCallback onOpenAlerts;
  final VoidCallback onOpenComplaints;
  final int unreadAlerts;

  @override
  State<InverterHomeView> createState() => _InverterHomeViewState();
}

class _InverterHomeViewState extends State<InverterHomeView> {
  bool _showAllChecks = false;

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
            _buildHeader(context),
            const SizedBox(height: ClaroSpacing.xl),
            if (widget.isLoading && widget.latest == null)
              const SizedBox(height: 320, child: Center(child: CircularProgressIndicator()))
            else if (widget.error != null && widget.latest == null)
              MessageState(
                icon: Icons.sync_problem_rounded,
                title: "Couldn't load inverter data",
                message: widget.error!,
                actionLabel: 'Try again',
                onAction: widget.onRefresh,
                isError: true,
              )
            else ...[
              _buildTopHeroCard(context),
              const SizedBox(height: ClaroSpacing.xl),
              if (widget.classification.isWarning || widget.classification.isFault) ...[
                _buildWhatNeedsAttention(context),
                const SizedBox(height: ClaroSpacing.xl),
              ],
              _buildRightNowGrid(context),
              const SizedBox(height: ClaroSpacing.xl),
              _buildStatusRows(context),
              const SizedBox(height: ClaroSpacing.xl),
              _buildHealthChecksCard(context),
              const SizedBox(height: ClaroSpacing.xl),
              _buildThisWeekChart(context),
              const SizedBox(height: ClaroSpacing.xl),
              _buildForYouTip(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final p = context.palette;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${greeting()}, ${widget.config.name}',
                  style: ClaroType.caption.copyWith(color: p.textMuted)),
              const SizedBox(height: 2),
              Text('Solar inverter', style: ClaroType.title.copyWith(color: p.text, fontSize: 24)),
              Text('STATCON GTI-1P · sno ${widget.config.rmuSno}',
                  style: ClaroType.caption.copyWith(color: p.accentText)),
            ],
          ),
        ),
        CircleIconButton(
          icon: Icons.notifications_none_rounded,
          tooltip: 'Alerts',
          badgeCount: widget.unreadAlerts,
          onPressed: widget.onOpenAlerts,
        ),
      ],
    );
  }

  Widget _buildTopHeroCard(BuildContext context) {
    final p = context.palette;
    final cls = widget.classification;
    final latest = widget.latest;
    final todayGen = widget.todayGraph?.todayGen ?? latest?.tkWh;
    final outputKw = (latest?.outputPowerWatts ?? 0) / 1000.0;

    Color badgeColor;
    switch (cls.kind) {
      case InverterStateKind.healthy:
        badgeColor = p.accentText;
      case InverterStateKind.warning:
        badgeColor = ClaroColors.warn;
      case InverterStateKind.fault:
        badgeColor = ClaroColors.fault;
      case InverterStateKind.resting:
      case InverterStateKind.noData:
        badgeColor = p.textMuted;
    }

    final updated = latest?.createdAt;
    final updatedText = updated != null ? 'Updated ${formatRelativeTime(updated.toIso8601String())}' : '';

    String mainLabel;
    String mainReadout;
    String unitLabel;
    String subtitleText;
    Color subtitleColor;

    if (cls.isFault) {
      mainLabel = 'Serving to grid now';
      mainReadout = '${latest?.outputPowerWatts.round() ?? 0}';
      unitLabel = 'W';
      subtitleText = 'Panels are working, but no power is reaching the grid. Energy today ${todayGen == null ? '0.0' : formatOneDecimal(todayGen)} kWh. $updatedText';
      subtitleColor = ClaroColors.fault;
    } else if (cls.isWarning) {
      mainLabel = 'Energy made today';
      mainReadout = todayGen == null ? '—' : formatOneDecimal(todayGen);
      unitLabel = 'kWh';
      subtitleText = '32% producing. Grid frequency is unsteady. $updatedText';
      subtitleColor = ClaroColors.warn;
    } else {
      mainLabel = 'Energy made today';
      mainReadout = todayGen == null ? '—' : formatOneDecimal(todayGen);
      unitLabel = 'kWh';
      subtitleText = outputKw > 0
          ? 'Sending ${formatOneDecimal(outputKw)} kW to the grid now. $updatedText'
          : 'Inverter ready. $updatedText';
      subtitleColor = p.accentText;
    }

    return Panel(
      padding: const EdgeInsets.all(ClaroSpacing.xl),
      child: Column(
        children: [
          Row(
            children: [
              StatusChip(label: cls.label, color: badgeColor, pulse: cls.isHealthy),
              const Spacer(),
              GestureDetector(
                onTap: widget.onOpenDetails,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: ClaroSpacing.md, vertical: 6),
                  decoration: BoxDecoration(
                    color: p.panelHigh,
                    borderRadius: ClaroRadius.pill,
                    border: Border.all(color: p.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Details', style: ClaroType.caption.copyWith(color: p.accentText)),
                      Icon(Icons.chevron_right_rounded, size: 14, color: p.accentText),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: ClaroSpacing.xl),
          InverterGraphic(kind: cls.kind),
          const SizedBox(height: ClaroSpacing.xl),
          Text(mainLabel, style: ClaroType.label.copyWith(color: p.textMuted)),
          const SizedBox(height: ClaroSpacing.xs),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                mainReadout,
                style: ClaroType.readoutXl.copyWith(color: p.text, fontSize: 40),
              ),
              const SizedBox(width: ClaroSpacing.xs),
              Text(unitLabel, style: ClaroType.title.copyWith(color: p.textMuted)),
            ],
          ),
          const SizedBox(height: ClaroSpacing.sm),
          Text(
            subtitleText,
            textAlign: TextAlign.center,
            style: ClaroType.caption.copyWith(color: subtitleColor),
          ),
        ],
      ),
    );
  }

  Widget _buildWhatNeedsAttention(BuildContext context) {
    final p = context.palette;
    final cls = widget.classification;
    final accentColor = cls.isFault ? ClaroColors.fault : ClaroColors.warn;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'WHAT NEEDS ATTENTION'),
        const SizedBox(height: ClaroSpacing.md),
        for (final issue in cls.issues) ...[
          Panel(
            color: accentColor.withValues(alpha: 0.08),
            borderColor: accentColor.withValues(alpha: 0.35),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(issue.title, style: ClaroType.subtitle.copyWith(color: accentColor, fontWeight: FontWeight.bold)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: ClaroSpacing.sm, vertical: 2),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.15),
                        borderRadius: ClaroRadius.pill,
                      ),
                      child: Text(issue.tag, style: ClaroType.caption.copyWith(color: accentColor)),
                    ),
                  ],
                ),
                const SizedBox(height: ClaroSpacing.sm),
                Text('Where: ${issue.where}', style: ClaroType.caption.copyWith(color: p.textMuted)),
                if (issue.id == 'grid_voltage') ...[
                  const SizedBox(height: ClaroSpacing.md),
                  _buildFlowDiagram(context),
                ],
                const SizedBox(height: ClaroSpacing.md),
                Text(issue.whatToDo, style: ClaroType.body.copyWith(color: p.text)),
              ],
            ),
          ),
          const SizedBox(height: ClaroSpacing.md),
        ],
        const SizedBox(height: ClaroSpacing.md),
        SectionHeader(title: cls.isFault ? 'TRY THESE FIRST' : 'IF IT KEEPS HAPPENING, TRY THESE'),
        const SizedBox(height: ClaroSpacing.md),
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < cls.tryTheseFirst.length; i++) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: ClaroSpacing.xs),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: p.panelHigh,
                        ),
                        alignment: Alignment.center,
                        child: Text('${i + 1}', style: ClaroType.caption.copyWith(color: p.text, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: ClaroSpacing.md),
                      Expanded(
                        child: Text(cls.tryTheseFirst[i], style: ClaroType.body.copyWith(color: p.text)),
                      ),
                    ],
                  ),
                ),
                if (i < cls.tryTheseFirst.length - 1)
                  Divider(height: 16, color: p.border),
              ],
            ],
          ),
        ),
        if (cls.isFault) ...[
          const SizedBox(height: ClaroSpacing.lg),
          ClaroPrimaryButton(
            text: 'Raise a complaint',
            onPressed: widget.onOpenComplaints,
          ),
        ],
      ],
    );
  }

  Widget _buildFlowDiagram(BuildContext context) {
    final p = context.palette;
    final stages = [
      ('Panels', false),
      ('DCDB', false),
      ('Inverter', false),
      ('ACDB', true),
      ('Grid', false),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < stages.length; i++) ...[
            if (i > 0)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Icon(Icons.arrow_forward_rounded, size: 12, color: p.textMuted),
              ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: stages[i].$2 ? ClaroColors.fault.withValues(alpha: 0.2) : p.panelHigh,
                borderRadius: ClaroRadius.pill,
                border: Border.all(
                  color: stages[i].$2 ? ClaroColors.fault : p.border,
                ),
              ),
              child: Text(
                stages[i].$1,
                style: ClaroType.caption.copyWith(
                  color: stages[i].$2 ? ClaroColors.fault : p.text,
                  fontWeight: stages[i].$2 ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRightNowGrid(BuildContext context) {
    final r = widget.latest;
    final solarKw = (r?.pvp ?? 0) / 1000.0;
    final outputKw = (r?.outputPowerWatts ?? 0) / 1000.0;
    final isFault = widget.classification.isFault;
    final isWarn = widget.classification.isWarning;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'RIGHT NOW'),
        const SizedBox(height: ClaroSpacing.md),
        Row(
          children: [
            Expanded(
              child: _GridTile(
                label: 'Solar power',
                value: '${formatOneDecimal(solarKw)} kW',
              ),
            ),
            const SizedBox(width: ClaroSpacing.sm),
            Expanded(
              child: _GridTile(
                label: 'Output power',
                value: '${formatOneDecimal(outputKw)} kW',
                highlightColor: isFault ? ClaroColors.fault : null,
              ),
            ),
            const SizedBox(width: ClaroSpacing.sm),
            Expanded(
              child: _GridTile(
                label: 'Solar voltage',
                value: '${r?.pvv == null ? '—' : r!.pvv!.round()} V',
              ),
            ),
          ],
        ),
        const SizedBox(height: ClaroSpacing.sm),
        Row(
          children: [
            Expanded(
              child: _GridTile(
                label: 'Grid voltage',
                value: '${r?.gv == null ? '—' : r!.gv!.round()} V',
                highlightColor: isFault && (r?.gov == true || r?.guv == true) ? ClaroColors.fault : null,
              ),
            ),
            const SizedBox(width: ClaroSpacing.sm),
            Expanded(
              child: _GridTile(
                label: 'Grid freq',
                value: '${formatOneDecimal(r?.gHz)} Hz',
                highlightColor: isWarn && (r?.gof == true || r?.guf == true) ? ClaroColors.warn : null,
              ),
            ),
            const SizedBox(width: ClaroSpacing.sm),
            Expanded(
              child: _GridTile(
                label: 'Inverter temp',
                value: '${r?.it == null ? '—' : r!.it!.round()} °C',
                highlightColor: (r?.it ?? 0) >= 65 ? ClaroColors.warn : null,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusRows(BuildContext context) {
    final p = context.palette;
    final r = widget.latest;
    final isFault = widget.classification.isFault;

    return Panel(
      padding: const EdgeInsets.symmetric(horizontal: ClaroSpacing.lg, vertical: ClaroSpacing.md),
      child: Column(
        children: [
          _RowItem(
            label: 'Inverter running',
            value: r?.irs == true ? 'Yes' : 'No',
            valueColor: r?.irs == true ? p.accentText : p.textMuted,
          ),
          Divider(height: 16, color: p.border),
          _RowItem(
            label: 'Grid connected',
            value: r?.grs == true ? 'Yes' : 'No',
            valueColor: r?.grs == true ? p.accentText : (isFault ? ClaroColors.fault : p.textMuted),
          ),
          Divider(height: 16, color: p.border),
          _RowItem(
            label: 'Lifetime energy',
            value: '${r?.tskWh == null ? '—' : formatWhole(r!.tskWh)} kWh',
            valueColor: p.text,
          ),
        ],
      ),
    );
  }

  Widget _buildHealthChecksCard(BuildContext context) {
    final p = context.palette;
    final cls = widget.classification;

    String checkTitle;
    String checkSub;
    Color iconColor;

    if (cls.isHealthy) {
      checkTitle = 'All 13 checks OK';
      checkSub = 'Grid, solar, DC bus, temperature and earth fault';
      iconColor = p.accentText;
    } else if (cls.isWarning) {
      checkTitle = '12 OK · 1 warning';
      checkSub = 'Tap to see every check';
      iconColor = ClaroColors.warn;
    } else if (cls.isFault) {
      checkTitle = '11 OK · 1 warning · 1 active';
      checkSub = 'Tap to see every check';
      iconColor = ClaroColors.fault;
    } else {
      checkTitle = 'Health checks';
      checkSub = 'Tap to see status';
      iconColor = p.textMuted;
    }

    return Panel(
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _showAllChecks = !_showAllChecks),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: iconColor.withValues(alpha: 0.14),
                  ),
                  child: Icon(cls.isHealthy ? Icons.check : Icons.health_and_safety_outlined, color: iconColor, size: 22),
                ),
                const SizedBox(width: ClaroSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(checkTitle, style: ClaroType.subtitle.copyWith(color: p.text, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text(checkSub, style: ClaroType.caption.copyWith(color: p.textMuted)),
                    ],
                  ),
                ),
                Icon(_showAllChecks ? Icons.expand_less_rounded : Icons.chevron_right_rounded, color: p.textMuted),
              ],
            ),
          ),
          if (_showAllChecks) ...[
            Divider(height: 20, color: p.border),
            _buildCheckList(context),
          ],
        ],
      ),
    );
  }

  Widget _buildCheckList(BuildContext context) {
    final p = context.palette;
    final r = widget.latest;
    final checks = <(String, String, String)>[
      ('Grid under-voltage', 'guv', r?.guv == true ? 'Active' : 'OK'),
      ('Grid under-frequency', 'guf', r?.guf == true ? 'Warning' : 'OK'),
      ('Grid over-voltage', 'gov', r?.gov == true ? 'Active' : 'OK'),
      ('Grid over-frequency', 'gof', r?.gof == true ? 'Warning' : 'OK'),
      ('Earth fault', 'ef', r?.ef == true ? 'Active' : 'OK'),
      ('DC wiring', 'dc', r?.dc == true ? 'Active' : 'OK'),
      ('Solar array over-voltage', 'pvov', r?.pvov == true ? 'Active' : 'OK'),
      ('Solar array under-voltage', 'pvuv', r?.pvuv == true ? 'Active' : 'OK'),
      ('Solar array over-current', 'pvoc', r?.pvoc == true ? 'Active' : 'OK'),
      ('DC bus over-voltage', 'dcov', r?.dcov == true ? 'Active' : 'OK'),
      ('DC bus under-voltage', 'dcuv', r?.dcuv == true ? 'Active' : 'OK'),
      ('Inverter over-current', 'ioc', r?.ioc == true ? 'Active' : 'OK'),
      ('Temperature', 'tmp', r?.tmp == true || (r?.it ?? 0) >= 65 ? 'Warning' : 'OK'),
    ];

    return Column(
      children: [
        for (final (title, _, status) in checks)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Text(title, style: ClaroType.body.copyWith(color: p.text)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: ClaroSpacing.sm, vertical: 2),
                  decoration: BoxDecoration(
                    color: status == 'Active'
                        ? ClaroColors.fault.withValues(alpha: 0.15)
                        : status == 'Warning'
                            ? ClaroColors.warn.withValues(alpha: 0.15)
                            : p.accentText.withValues(alpha: 0.15),
                    borderRadius: ClaroRadius.pill,
                  ),
                  child: Text(
                    status,
                    style: ClaroType.caption.copyWith(
                      color: status == 'Active'
                          ? ClaroColors.fault
                          : status == 'Warning'
                              ? ClaroColors.warn
                              : p.accentText,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildThisWeekChart(BuildContext context) {
    final p = context.palette;
    final points = widget.history7Days?.points ?? [];
    final total = points.map((pt) => pt.dkWh).whereType<double>().fold<double>(0, (a, b) => a + b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'THIS WEEK'),
        const SizedBox(height: ClaroSpacing.md),
        Panel(
          padding: const EdgeInsets.all(ClaroSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Last 7 days', style: ClaroType.caption.copyWith(color: p.textMuted)),
                  Text('${formatOneDecimal(total)} kWh', style: ClaroType.subtitle.copyWith(color: p.text, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: ClaroSpacing.lg),
              ClaroLineChart(
                points: points.map((pt) => pt.dkWh).toList(),
                xLabels: points.map((pt) => pt.label.split(',').last.trim()).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildForYouTip(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'FOR YOU'),
        const SizedBox(height: ClaroSpacing.md),
        Panel(
          color: const Color(0xFF1E1C18),
          borderColor: const Color(0xFF332E24),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF382F1D),
                ),
                child: const Icon(Icons.wb_sunny_outlined, color: ClaroColors.warn, size: 20),
              ),
              const SizedBox(width: ClaroSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Best hours today: 10 AM – 3 PM', style: ClaroType.subtitle.copyWith(color: ClaroColors.warn, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(
                      'Your inverter is producing well. Keep panels clean every few weeks with plain water, early morning.',
                      style: ClaroType.caption.copyWith(color: const Color(0xFFD4C8B8)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _GridTile extends StatelessWidget {
  const _GridTile({required this.label, required this.value, this.highlightColor});

  final String label;
  final String value;
  final Color? highlightColor;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final color = highlightColor;
    return Container(
      padding: const EdgeInsets.all(ClaroSpacing.sm),
      decoration: BoxDecoration(
        color: color != null ? color.withValues(alpha: 0.12) : p.panel,
        borderRadius: ClaroRadius.md,
        border: Border.all(
          color: color != null ? color.withValues(alpha: 0.5) : p.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: ClaroType.caption.copyWith(color: p.textMuted, fontSize: 11)),
          const SizedBox(height: 4),
          Text(value, style: ClaroType.title.copyWith(color: color ?? p.text, fontSize: 15, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _RowItem extends StatelessWidget {
  const _RowItem({required this.label, required this.value, required this.valueColor});

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: ClaroType.body.copyWith(color: p.textMuted)),
        Text(value, style: ClaroType.subtitle.copyWith(color: valueColor, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
