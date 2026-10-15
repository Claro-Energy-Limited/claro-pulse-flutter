import 'package:flutter/material.dart';

import '../../app/theme/claro_dimens.dart';
import '../../app/theme/claro_palette.dart';
import '../../app/theme/claro_type.dart';
import '../../core/api/models/pump_models.dart';
import '../common/ui_kit.dart';

/// A full-screen summary of one run, shown when a run ends (and from the
/// Last run card): a small moment that says "here's what your pump did".
Future<void> showRunStory(BuildContext context, {required PumpRun run, required String deviceName}) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: const Color(0x00000000),
    transitionDuration: const Duration(milliseconds: 350),
    pageBuilder: (context, _, _) => _RunStory(run: run, deviceName: deviceName),
    transitionBuilder: (context, animation, _, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(scale: Tween<double>(begin: 0.96, end: 1).animate(curved), child: child),
      );
    },
  );
}

class _RunStory extends StatelessWidget {
  const _RunStory({required this.run, required this.deviceName});

  final PumpRun run;
  final String deviceName;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final start = DateTime.tryParse(run.startedAt);
    final end = run.endedAt == null ? null : DateTime.tryParse(run.endedAt!);
    final when = start == null
        ? ''
        : '${formatDayName(start)} · ${formatClock(start)} – ${end == null ? 'now' : formatClock(end)}';

    return Scaffold(
      backgroundColor: p.bg,
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0, -0.5),
            radius: 1.0,
            colors: [p.accent.withValues(alpha: p.isDark ? 0.22 : 0.30), p.bg],
          ),
        ),
        child: SafeArea(
          // Scrolls on small screens; spaced out to fill taller ones.
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              padding: const EdgeInsets.all(ClaroSpacing.xl),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight - ClaroSpacing.xl * 2),
                child: IntrinsicHeight(
                  child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: CircleIconButton(
                    icon: Icons.close_rounded,
                    tooltip: 'Close',
                    size: 40,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                const Spacer(),
                Icon(Icons.water_drop_rounded, size: 40, color: p.accentText),
                const SizedBox(height: ClaroSpacing.md),
                Text(
                  run.isOngoing ? 'Running now' : 'Run complete',
                  textAlign: TextAlign.center,
                  style: ClaroType.title.copyWith(color: p.text),
                ),
                Text(
                  '$deviceName · $when',
                  textAlign: TextAlign.center,
                  style: ClaroType.caption.copyWith(color: p.textMuted),
                ),
                const SizedBox(height: ClaroSpacing.xxl),
                CountUpText(
                  value: run.waterLiters,
                  format: formatWhole,
                  duration: const Duration(milliseconds: 1200),
                  style: ClaroType.readoutXl.copyWith(color: p.text, fontSize: 56, height: 1.1),
                ),
                Text(
                  run.isOngoing ? 'litres so far' : 'litres of water',
                  textAlign: TextAlign.center,
                  style: ClaroType.subtitle.copyWith(color: p.textMuted),
                ),
                const SizedBox(height: ClaroSpacing.xxl),
                Panel(
                  child: Row(
                    children: [
                      Expanded(child: MiniStat(label: 'Duration', value: formatDuration(run.duration()))),
                      Expanded(child: MiniStat(label: 'Average flow', value: '${formatWhole(run.avgFlowLpm)} L/min')),
                      Expanded(child: MiniStat(label: 'Energy', value: '${formatOneDecimal(run.energyKwh)} kWh')),
                    ],
                  ),
                ),
                const Spacer(),
                AccentButton(
                  text: 'Share',
                  icon: Icons.share_rounded,
                  onPressed: () => ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(const SnackBar(content: Text('Sharing is coming soon'))),
                ),
                const SizedBox(height: ClaroSpacing.sm),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Done', style: ClaroType.subtitle.copyWith(color: p.textMuted)),
                ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
