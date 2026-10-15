import 'package:flutter/material.dart';

import '../../app/theme/claro_dimens.dart';
import '../../app/theme/claro_palette.dart';
import '../../app/theme/claro_type.dart';
import '../../core/api/models/pump_models.dart';
import '../common/ui_kit.dart';

/// "Running now" while the pump runs, otherwise "Last run": when it ran, for
/// how long, and above all how much water it gave.
class LastRunCard extends StatelessWidget {
  const LastRunCard({super.key, required this.run, required this.onSeeAll, required this.onOpenStory});

  final PumpRun run;
  final VoidCallback onSeeAll;

  /// Opens the full-screen run story.
  final VoidCallback onOpenStory;

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
      onTap: onOpenStory,
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
                child: CountUpText(
                  value: run.waterLiters,
                  format: formatWhole,
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

/// One swipeable card in the "For you" row on Home.
class ContextCardData {
  const ContextCardData({
    required this.icon,
    required this.title,
    required this.body,
    this.tone = ContextTone.normal,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String body;
  final ContextTone tone;
  final VoidCallback? onTap;
}

enum ContextTone { normal, positive, warning }

/// "Next best action" cards, swiped one at a time: only what's useful right now.
class ContextCarousel extends StatefulWidget {
  const ContextCarousel({super.key, required this.cards, this.height = 148});

  final List<ContextCardData> cards;
  final double height;

  @override
  State<ContextCarousel> createState() => _ContextCarouselState();
}

class _ContextCarouselState extends State<ContextCarousel> {
  final _controller = PageController(viewportFraction: 0.9);
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final cards = widget.cards;
    return Column(
      children: [
        SizedBox(
          height: widget.height,
          child: PageView.builder(
            controller: _controller,
            padEnds: false,
            itemCount: cards.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (context, i) => Padding(
              padding: const EdgeInsets.only(right: ClaroSpacing.md),
              child: _ContextCard(data: cards[i]),
            ),
          ),
        ),
        if (cards.length > 1) ...[
          const SizedBox(height: ClaroSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < cards.length; i++)
                AnimatedContainer(
                  duration: ClaroMotion.fast,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: i == _page ? 18 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: i == _page ? p.accentText : p.border,
                    borderRadius: ClaroRadius.pill,
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _ContextCard extends StatelessWidget {
  const _ContextCard({required this.data});

  final ContextCardData data;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final (Color tint, bool tinted) = switch (data.tone) {
      ContextTone.warning => (p.warnText, true),
      ContextTone.positive => (p.accentText, true),
      ContextTone.normal => (p.accentText, false),
    };
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconTile(icon: data.icon, color: tint, size: 36),
            const Spacer(),
            if (data.onTap != null) Icon(Icons.arrow_forward_rounded, size: 18, color: p.textMuted),
          ],
        ),
        const SizedBox(height: ClaroSpacing.md),
        Text(
          data.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: ClaroType.subtitle.copyWith(color: p.text, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 2),
        Expanded(
          child: Text(
            data.body,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: ClaroType.caption.copyWith(color: p.textMuted),
          ),
        ),
      ],
    );
    return tinted
        ? TintedPanel(tint: data.tone == ContextTone.warning ? p.warn : p.accent, onTap: data.onTap, child: content)
        : Panel(onTap: data.onTap, child: content);
  }
}
