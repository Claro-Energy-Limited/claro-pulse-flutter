import 'package:flutter/material.dart';

import '../../app/theme/claro_dimens.dart';
import '../../app/theme/claro_palette.dart';
import '../../app/theme/claro_type.dart';
import '../../core/api/models/pump_models.dart';
import '../common/ui_kit.dart';

/// "Running now" while the pump runs, otherwise "Last run": when it ran, for
/// how long, and above all how much water it gave.
class LastRunCard extends StatelessWidget {
  const LastRunCard({super.key, required this.run, required this.onSeeAll});

  final PumpRun run;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final start = DateTime.tryParse(run.startedAt);
    final end = run.endedAt == null ? null : DateTime.tryParse(run.endedAt!);
    final ongoing = run.isOngoing;

    final String when;
    if (start == null) {
      when = '';
    } else if (ongoing) {
      final day = formatDayName(start);
      final dayText = day == 'Today' || day == 'Yesterday' ? day.toLowerCase() : 'on $day';
      when = 'Started ${formatClock(start)} $dayText';
    } else {
      when = '${formatDayName(start)}, ${formatClock(start)} – ${end == null ? '?' : formatClock(end)}';
    }

    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconTile(icon: ongoing ? Icons.water_drop_rounded : Icons.history_rounded),
              const SizedBox(width: ClaroSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ongoing ? 'Running now' : 'Last run',
                      style: ClaroType.subtitle.copyWith(
                        color: ongoing ? p.accentText : p.text,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(when, style: ClaroType.caption.copyWith(color: p.textMuted)),
                  ],
                ),
              ),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onSeeAll,
                child: Padding(
                  padding: const EdgeInsets.all(ClaroSpacing.xs),
                  child: Text('All runs', style: ClaroType.label.copyWith(color: p.accentText)),
                ),
              ),
            ],
          ),
          const SizedBox(height: ClaroSpacing.lg),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: Text(
                  formatWhole(run.waterLiters),
                  overflow: TextOverflow.ellipsis,
                  style: ClaroType.readoutLg.copyWith(color: p.text),
                ),
              ),
              const SizedBox(width: ClaroSpacing.sm),
              Flexible(
                child: Text(
                  ongoing ? 'litres so far' : 'litres pumped',
                  style: ClaroType.body.copyWith(color: p.textMuted),
                ),
              ),
            ],
          ),
          const SizedBox(height: ClaroSpacing.lg),
          Row(
            children: [
              Expanded(child: MiniStat(label: 'Duration', value: formatDuration(run.duration()))),
              Expanded(child: MiniStat(label: 'Average flow', value: '${formatWhole(run.avgFlowLpm)} L/min')),
              Expanded(child: MiniStat(label: 'Energy', value: '${formatOneDecimal(run.energyKwh)} kWh')),
            ],
          ),
        ],
      ),
    );
  }
}

/// A short list of recent runs: day, times, duration, litres.
class RecentRunsList extends StatelessWidget {
  const RecentRunsList({super.key, required this.runs});

  final List<PumpRun> runs;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Panel(
      padding: const EdgeInsets.symmetric(horizontal: ClaroSpacing.lg, vertical: ClaroSpacing.xs),
      child: Column(
        children: [
          for (var i = 0; i < runs.length; i++) ...[
            if (i > 0) Divider(height: 1, color: p.border),
            _RunRow(run: runs[i]),
          ],
        ],
      ),
    );
  }
}

class _RunRow extends StatelessWidget {
  const _RunRow({required this.run});

  final PumpRun run;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final start = DateTime.tryParse(run.startedAt);
    final end = run.endedAt == null ? null : DateTime.tryParse(run.endedAt!);
    final times = start == null
        ? ''
        : run.isOngoing
            ? '${formatClock(start)} – now'
            : '${formatClock(start)} – ${end == null ? '?' : formatClock(end)}';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: ClaroSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        start == null ? 'Run' : formatDayName(start),
                        style: ClaroType.subtitle.copyWith(color: p.text),
                      ),
                    ),
                    if (run.isOngoing) ...[
                      const SizedBox(width: ClaroSpacing.sm),
                      Text('Running', style: ClaroType.caption.copyWith(color: p.accentText)),
                    ],
                  ],
                ),
                Text(
                  '$times · ${formatDuration(run.duration())}',
                  style: ClaroType.caption.copyWith(color: p.textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(width: ClaroSpacing.md),
          Text('${formatWhole(run.waterLiters)} L', style: ClaroType.readout.copyWith(color: p.text)),
        ],
      ),
    );
  }
}

IconData weatherIcon(WeatherCondition c) => switch (c) {
      WeatherCondition.sunny => Icons.wb_sunny_rounded,
      WeatherCondition.partlyCloudy => Icons.wb_cloudy_outlined,
      WeatherCondition.cloudy => Icons.cloud_rounded,
      WeatherCondition.rain => Icons.grain_rounded,
    };

/// Today's weather, the best hours to pump, and tomorrow's expected water.
class WeatherCard extends StatelessWidget {
  const WeatherCard({super.key, required this.insights});

  final PumpInsights insights;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final i = insights;
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconTile(icon: weatherIcon(i.todayCondition), color: p.warnText, size: 48),
              const SizedBox(width: ClaroSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${i.todayCondition.label} · ${i.todayTempC}°C',
                      style: ClaroType.subtitle.copyWith(color: p.text, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      'Best time to run: ${i.bestHours}',
                      style: ClaroType.caption.copyWith(color: p.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: ClaroSpacing.md),
          Divider(height: 1, color: p.border),
          const SizedBox(height: ClaroSpacing.md),
          Row(
            children: [
              Icon(weatherIcon(i.tomorrowCondition), size: 20, color: p.textMuted),
              const SizedBox(width: ClaroSpacing.sm),
              Expanded(
                child: Text(
                  'Tomorrow: ${i.tomorrowCondition.label.toLowerCase()}, ${i.tomorrowTempC}°C',
                  style: ClaroType.body.copyWith(color: p.text),
                ),
              ),
            ],
          ),
          const SizedBox(height: ClaroSpacing.xs),
          Padding(
            padding: const EdgeInsets.only(left: 28),
            child: Text(
              'About ${formatWhole(i.tomorrowExpectedLiters)} litres expected',
              style: ClaroType.caption.copyWith(color: p.accentText),
            ),
          ),
        ],
      ),
    );
  }
}

/// How much the farmer saved compared with a diesel pump.
class SavingsCard extends StatelessWidget {
  const SavingsCard({super.key, required this.insights});

  final PumpInsights insights;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final i = insights;
    return TintedPanel(
      tint: p.accent,
      child: Row(
        children: [
          IconTile(icon: Icons.savings_rounded, size: 48),
          const SizedBox(width: ClaroSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Saved this month', style: ClaroType.caption.copyWith(color: p.textMuted)),
                Text(
                  '₹${formatWhole(i.savingsThisMonthRupees)}',
                  style: ClaroType.readoutLg.copyWith(color: p.text, fontSize: 26),
                ),
                Text(
                  '₹${formatWhole(i.savingsTotalRupees)} since installation · '
                  '${formatWhole(i.dieselSavedLiters)} litres of diesel saved',
                  style: ClaroType.caption.copyWith(color: p.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A reminder to clean the panels when output is lower than the sun suggests.
class PanelCareCard extends StatelessWidget {
  const PanelCareCard({super.key, required this.insights});

  final PumpInsights insights;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final cleaned = DateTime.tryParse(insights.lastCleanedOn);
    final days = cleaned == null ? null : DateTime.now().difference(cleaned).inDays;
    final last = days == null
        ? ''
        : days <= 0
            ? 'Last cleaned today.'
            : 'Last cleaned $days day${days == 1 ? '' : 's'} ago.';

    if (!insights.panelsNeedCleaning) {
      return Panel(
        child: Row(
          children: [
            const IconTile(icon: Icons.solar_power_rounded),
            const SizedBox(width: ClaroSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Solar panels look clean', style: ClaroType.subtitle.copyWith(color: p.text)),
                  Text(last, style: ClaroType.caption.copyWith(color: p.textMuted)),
                ],
              ),
            ),
          ],
        ),
      );
    }
    return TintedPanel(
      tint: p.warn,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconTile(icon: Icons.cleaning_services_rounded, color: p.warnText),
          const SizedBox(width: ClaroSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Time to clean your solar panels',
                  style: ClaroType.subtitle.copyWith(color: p.text, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  'Your pump is giving less water than expected for this much sun. Dust on the panels is the usual cause. $last',
                  style: ClaroType.body.copyWith(color: p.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
