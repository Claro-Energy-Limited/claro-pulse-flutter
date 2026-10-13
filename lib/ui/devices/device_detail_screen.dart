import 'package:flutter/material.dart';

import '../../app/theme/claro_colors.dart';
import '../../app/theme/claro_dimens.dart';
import '../../app/theme/claro_type.dart';
import '../../core/api/api_exception.dart';
import '../../core/api/claro_pulse_api.dart';
import '../../core/api/models/device_models.dart';
import '../components/claro_line_chart.dart';
import '../components/claro_primary_button.dart';
import '../components/device_hero_card.dart';
import 'device_kind.dart';
import 'device_metrics.dart';
import 'device_status_banners.dart';

/// One device in full, ported from the Kotlin `DeviceDetailScreen`: the hero
/// card, run/fault/protection banners, and (pumps only) an activity chart with
/// day, week and month ranges.
///
/// Fetches its own status rather than reading Home's cache: the farmer may open
/// a device Home has never shown. Inverters never request activity, because the
/// API has no inverter history.
class DeviceDetailScreen extends StatefulWidget {
  const DeviceDetailScreen({super.key, required this.device, required this.api, required this.onBack});

  final MyDevice device;
  final ClaroPulseApi api;
  final VoidCallback onBack;

  @override
  State<DeviceDetailScreen> createState() => _DeviceDetailScreenState();
}

class _DeviceDetailScreenState extends State<DeviceDetailScreen> {
  late final DeviceKind _kind = DeviceKind.from(widget.device.kind);

  DeviceStatus? _status;
  String? _statusError;

  ActivityRange _range = ActivityRange.day;
  ActivitySeries _series = ActivitySeries.runHours;
  DeviceActivity? _activity;
  String? _activityError;
  bool _isLoadingActivity = false;

  /// Bumped per activity request, so a slow answer for a range the farmer has
  /// already left never overwrites the newer one.
  int _activityRequest = 0;

  @override
  void initState() {
    super.initState();
    _loadStatus();
    if (_kind == DeviceKind.pump) _loadActivity();
  }

  Future<void> _loadStatus() async {
    setState(() => _statusError = null);
    try {
      final status = await widget.api.getDeviceStatus(widget.device.deviceId);
      if (!mounted) return;
      setState(() => _status = status);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _statusError = e.message);
    }
  }

  /// Keeps the previous range's chart on screen while the new one loads; the
  /// spinner only shows when there is nothing to show yet.
  Future<void> _loadActivity() async {
    final request = ++_activityRequest;
    setState(() {
      _isLoadingActivity = true;
      _activityError = null;
    });
    try {
      final activity = await widget.api.getDeviceActivity(widget.device.deviceId, _range);
      if (!mounted || request != _activityRequest) return;
      setState(() {
        _activity = activity;
        _isLoadingActivity = false;
      });
    } on ApiException catch (e) {
      if (!mounted || request != _activityRequest) return;
      setState(() {
        _activityError = e.message;
        _isLoadingActivity = false;
      });
    }
  }

  void _selectRange(ActivityRange range) {
    if (range == _range) return;
    setState(() => _range = range);
    _loadActivity();
  }

  @override
  Widget build(BuildContext context) {
    final status = _status;
    return Scaffold(
      backgroundColor: ClaroColors.ink,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(ClaroSpacing.lg),
              child: Row(
                children: [
                  Tooltip(
                    message: 'Back',
                    child: Material(
                      color: ClaroColors.inkPanel,
                      shape: const CircleBorder(),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: widget.onBack,
                        child: const SizedBox.square(
                          dimension: 36,
                          child: Icon(Icons.arrow_back, size: 20, color: ClaroColors.onInk),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: ClaroSpacing.md),
                  Expanded(
                    child: Text(
                      widget.device.deviceUid,
                      style: ClaroType.title.copyWith(color: ClaroColors.onInk),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: ClaroSpacing.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (status != null)
                      DeviceHeroCard(
                        kind: _kind,
                        isRunning: isDeviceRunning(status),
                        callouts: heroCalloutsFor(_kind, status),
                        todaySummary: heroTodaySummaryFor(_kind, status),
                        comingSoon: _kind == DeviceKind.inverter,
                      )
                    else if (_statusError == null)
                      const SizedBox(
                        height: 200,
                        child: Center(child: CircularProgressIndicator(color: ClaroColors.mint)),
                      ),
                    const SizedBox(height: ClaroSpacing.xl),
                    if (_statusError != null && status == null)
                      _Retry(message: "Couldn't load this device's data", onRetry: _loadStatus)
                    else if (status != null)
                      DeviceStatusBanners(status: status),
                    const SizedBox(height: ClaroSpacing.xxl),
                    if (_kind == DeviceKind.pump) _historySection() else const _InverterNote(),
                    const SizedBox(height: ClaroSpacing.xl),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _historySection() {
    final activity = _activity;
    final Widget chart;
    if (activity != null) {
      chart = ClaroLineChart(
        points: activityChartValues(activity.points, _series),
        xLabels: activityChartLabels(activity.points, _range),
      );
    } else if (!_isLoadingActivity && _activityError != null) {
      chart = _Retry(message: "Couldn't load history", onRetry: _loadActivity);
    } else {
      chart = const SizedBox(
        height: 196,
        child: Center(child: CircularProgressIndicator(color: ClaroColors.mint)),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('History', style: ClaroType.title.copyWith(color: ClaroColors.onInk)),
        const SizedBox(height: ClaroSpacing.md),
        Row(
          spacing: ClaroSpacing.sm,
          children: [
            for (final s in ActivitySeries.values)
              _Pill(text: s.label, selected: s == _series, onTap: () => setState(() => _series = s)),
          ],
        ),
        const SizedBox(height: ClaroSpacing.sm),
        Row(
          spacing: ClaroSpacing.sm,
          children: [
            for (final r in ActivityRange.values)
              _Pill(text: _rangeLabel(r), selected: r == _range, onTap: () => _selectRange(r)),
          ],
        ),
        const SizedBox(height: ClaroSpacing.lg),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(ClaroSpacing.lg),
          decoration: BoxDecoration(color: ClaroColors.inkPanel, borderRadius: ClaroRadius.lg),
          child: chart,
        ),
      ],
    );
  }

  static String _rangeLabel(ActivityRange r) => switch (r) {
        ActivityRange.day => 'Day',
        ActivityRange.week => 'Week',
        ActivityRange.month => 'Month',
      };
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text, required this.selected, required this.onTap});

  final String text;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? ClaroColors.mint : ClaroColors.inkPanel,
        borderRadius: ClaroRadius.pill,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: ClaroSpacing.md, vertical: ClaroSpacing.sm),
            child: Text(
              text,
              style: ClaroType.label.copyWith(color: selected ? ClaroColors.ink : ClaroColors.onInkMuted),
            ),
          ),
        ),
      ),
    );
  }
}

class _Retry extends StatelessWidget {
  const _Retry({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(message, style: ClaroType.body.copyWith(color: ClaroColors.onInkMuted), textAlign: TextAlign.center),
        const SizedBox(height: ClaroSpacing.md),
        ClaroPrimaryButton(text: 'Try again', onPressed: onRetry),
      ],
    );
  }
}

class _InverterNote extends StatelessWidget {
  const _InverterNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(ClaroSpacing.xl),
      decoration: BoxDecoration(color: ClaroColors.inkPanel, borderRadius: ClaroRadius.lg),
      child: Text(
        'Historical charts will appear here once this device starts reporting extended telemetry.',
        style: ClaroType.body.copyWith(color: ClaroColors.onInkMuted),
      ),
    );
  }
}
