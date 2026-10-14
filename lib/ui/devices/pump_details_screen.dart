import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme/claro_colors.dart';
import '../../app/theme/claro_dimens.dart';
import '../../app/theme/claro_type.dart';
import '../../core/api/api_exception.dart';
import '../../core/api/claro_pulse_api.dart';
import '../../core/api/models/device_models.dart';
import '../../core/api/models/pump_models.dart';
import '../common/ui_kit.dart';
import '../home/home_dashboard.dart' show deviceTitle;
import 'device_kind.dart';

/// Everything about the installed pump that doesn't change: model, IMEI,
/// installation and warranty. The things a farmer reads out on a service call.
class PumpDetailsScreen extends StatefulWidget {
  const PumpDetailsScreen({super.key, required this.device, required this.api, required this.onBack});

  final MyDevice device;
  final ClaroPulseApi api;
  final VoidCallback onBack;

  @override
  State<PumpDetailsScreen> createState() => _PumpDetailsScreenState();
}

class _PumpDetailsScreenState extends State<PumpDetailsScreen> {
  PumpDetails? _details;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final details = await widget.api.getPumpDetails(widget.device.deviceId);
      if (mounted) setState(() => _details = details);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  void _copy(String label, String value) {
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$label copied')));
  }

  @override
  Widget build(BuildContext context) {
    final device = widget.device;
    final isInverter = DeviceKind.from(device.kind) == DeviceKind.inverter;
    final details = _details;
    return Scaffold(
      backgroundColor: context.bg,
      body: SafeArea(
        child: Column(
          children: [
            BackHeader(title: isInverter ? 'Inverter details' : 'Pump details', onBack: widget.onBack),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(ClaroSpacing.xl, ClaroSpacing.sm, ClaroSpacing.xl, ClaroSpacing.xxl),
                children: [
                  _Summary(device: device, details: details, isInverter: isInverter),
                  const SizedBox(height: ClaroSpacing.xl),
                  if (details == null && _error == null)
                    SizedBox(height: 200, child: Center(child: CircularProgressIndicator(color: context.brandMint)))
                  else if (details == null)
                    MessageState(
                      icon: Icons.info_outline_rounded,
                      title: "Details aren't available",
                      message: _error!,
                      actionLabel: 'Try again',
                      onAction: _load,
                      isError: true,
                    )
                  else ...[
                    _Group(title: 'Device', rows: [
                      _InfoRow('IMEI', details.imei, onCopy: () => _copy('IMEI', details.imei), mono: true),
                      _InfoRow('Serial number', details.serialNo ?? dash, mono: true),
                      _InfoRow('Device ID', device.deviceUid, mono: true),
                      _InfoRow('Controller', details.controller),
                      _InfoRow('Solar panels', details.panels),
                    ]),
                    const SizedBox(height: ClaroSpacing.lg),
                    _Group(title: 'Installation', rows: [
                      _InfoRow('Installed on', formatDate(details.installedOn)),
                      _InfoRow('Installed by', details.installedBy),
                      _InfoRow('Site', details.siteAddress),
                    ]),
                    const SizedBox(height: ClaroSpacing.lg),
                    _Warranty(until: details.warrantyUntil),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.device, required this.details, required this.isInverter});

  final MyDevice device;
  final PumpDetails? details;
  final bool isInverter;

  @override
  Widget build(BuildContext context) {
    final details = this.details;
    return Panel(
      padding: const EdgeInsets.all(ClaroSpacing.lg),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: ClaroRadius.md,
            child: Container(
              width: 96,
              height: 96,
              color: context.panelHigh,
              padding: isInverter ? EdgeInsets.zero : const EdgeInsets.all(ClaroSpacing.sm),
              child: Image.asset(
                isInverter ? 'assets/images/device_hero_inverter.png' : 'assets/images/device_hero_pump.png',
                fit: isInverter ? BoxFit.cover : BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(width: ClaroSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  details?.model ?? deviceTitle(device),
                  style: ClaroType.subtitle.copyWith(color: context.textPrimary, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: ClaroSpacing.xs),
                if (details != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: ClaroSpacing.sm, vertical: 2),
                    decoration: BoxDecoration(
                      color: context.brandMint.withValues(alpha: 0.14),
                      borderRadius: ClaroRadius.pill,
                    ),
                    child: Text(details.capacity, style: ClaroType.caption.copyWith(color: context.brandMint)),
                  ),
                const SizedBox(height: ClaroSpacing.xs),
                Text(device.deviceUid, style: ClaroType.caption.copyWith(color: context.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow {
  const _InfoRow(this.label, this.value, {this.onCopy, this.mono = false});

  final String label;
  final String value;
  final VoidCallback? onCopy;
  final bool mono;
}

class _Group extends StatelessWidget {
  const _Group({required this.title, required this.rows});

  final String title;
  final List<_InfoRow> rows;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: title),
        const SizedBox(height: ClaroSpacing.sm),
        Panel(
          padding: const EdgeInsets.symmetric(horizontal: ClaroSpacing.lg, vertical: ClaroSpacing.xs),
          child: Column(
            children: [
              for (var i = 0; i < rows.length; i++) ...[
                if (i > 0) Divider(height: 1, color: context.border),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: ClaroSpacing.md),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 110,
                        child: Text(rows[i].label, style: ClaroType.body.copyWith(color: context.textSecondary)),
                      ),
                      Expanded(
                        child: Text(
                          rows[i].value,
                          textAlign: TextAlign.end,
                          style: (rows[i].mono ? ClaroType.readoutSm : ClaroType.body)
                              .copyWith(color: context.textPrimary),
                        ),
                      ),
                      if (rows[i].onCopy != null) ...[
                        const SizedBox(width: ClaroSpacing.sm),
                        GestureDetector(
                          onTap: rows[i].onCopy,
                          child: Tooltip(
                            message: 'Copy ${rows[i].label}',
                            child: Icon(Icons.copy_rounded, size: 16, color: context.brandMint),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _Warranty extends StatelessWidget {
  const _Warranty({required this.until});

  final String until;

  @override
  Widget build(BuildContext context) {
    final end = DateTime.tryParse(until);
    final active = end != null && end.isAfter(DateTime.now());
    final color = active ? context.brandMint : ClaroColors.fault;
    return Panel(
      child: Row(
        children: [
          Icon(active ? Icons.verified_user_rounded : Icons.gpp_bad_rounded, color: color),
          const SizedBox(width: ClaroSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  active ? 'Under warranty' : 'Warranty ended',
                  style: ClaroType.subtitle.copyWith(color: context.textPrimary),
                ),
                Text(
                  '${active ? 'Valid until' : 'Ended on'} ${formatDate(until)}',
                  style: ClaroType.caption.copyWith(color: context.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
