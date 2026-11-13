import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme/claro_dimens.dart';
import '../../app/theme/claro_palette.dart';
import '../../app/theme/claro_type.dart';
import '../../config/demo_users.dart';
import '../../core/models/smartnet_models.dart';
import '../common/ui_kit.dart';

class InverterDetailsView extends StatelessWidget {
  const InverterDetailsView({
    super.key,
    required this.config,
    required this.latest,
    required this.onBack,
  });

  final DemoUserConfig config;
  final SmartnetLatestReading? latest;
  final VoidCallback onBack;

  void _copy(BuildContext context, String label, String value) {
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$label copied')));
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final r = latest;
    return Scaffold(
      backgroundColor: p.bg,
      body: SafeArea(
        child: Column(
          children: [
            BackHeader(title: 'Inverter details', onBack: onBack),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(ClaroSpacing.xl, ClaroSpacing.sm, ClaroSpacing.xl, kNavClearance),
                children: [
                  _buildSummaryCard(context),
                  const SizedBox(height: ClaroSpacing.xl),
                  _buildGroup(context, 'Site & Customer', [
                    _DetailRow('Customer name', config.name),
                    _DetailRow('Site name', config.siteName),
                    _DetailRow('District & state', config.districtState),
                    _DetailRow('Installed on', formatDate(config.installedDate)),
                  ]),
                  const SizedBox(height: ClaroSpacing.lg),
                  _buildGroup(context, 'Inverter Specifications', [
                    _DetailRow('Model', config.model),
                    _DetailRow('Rating', '${config.ratingKva} kVA'),
                    _DetailRow('Panel capacity', '${config.panelCapacityKwp} kWp'),
                    _DetailRow('Inverter serial', config.inverterSerial, mono: true, onCopy: () => _copy(context, 'Inverter serial', config.inverterSerial)),
                    _DetailRow('RMU serial (sno)', config.rmuSno, mono: true, onCopy: () => _copy(context, 'RMU serial', config.rmuSno)),
                    _DetailRow('RMU IMEI', config.rmuImei, mono: true, onCopy: () => _copy(context, 'RMU IMEI', config.rmuImei)),
                  ]),
                  const SizedBox(height: ClaroSpacing.lg),
                  if (r != null) ...[
                    _buildGroup(context, 'Live Telemetry Readings', [
                      _DetailRow('Solar voltage (pvv)', r.pvv == null ? '—' : '${formatOneDecimal(r.pvv)} V'),
                      _DetailRow('Solar current (pvi)', r.pvi == null ? '—' : '${formatOneDecimal(r.pvi)} A'),
                      _DetailRow('Solar power (pvp)', r.pvp == null ? '—' : '${formatWhole(r.pvp)} W'),
                      _DetailRow('Output power (calc)', '${formatWhole(r.outputPowerWatts)} W'),
                      _DetailRow('DC bus voltage (dcv)', r.dcv == null ? '—' : '${formatOneDecimal(r.dcv)} V'),
                      _DetailRow('Inverter voltage (iv)', r.iv == null ? '—' : '${formatOneDecimal(r.iv)} V'),
                      _DetailRow('Inverter current (ii)', r.ii == null ? '—' : '${formatOneDecimal(r.ii)} A'),
                      _DetailRow('Inverter frequency (iHz)', r.iHz == null ? '—' : '${formatOneDecimal(r.iHz)} Hz'),
                      _DetailRow('Grid voltage (gv)', r.gv == null ? '—' : '${formatOneDecimal(r.gv)} V'),
                      _DetailRow('Grid frequency (gHz)', r.gHz == null ? '—' : '${formatOneDecimal(r.gHz)} Hz'),
                      _DetailRow('Inverter temperature (it)', r.it == null ? '—' : '${formatOneDecimal(r.it)} °C'),
                      _DetailRow('Lifetime total (tskWh)', r.tskWh == null ? '—' : '${formatWhole(r.tskWh)} kWh'),
                      _DetailRow('Today energy (tkWh)', r.tkWh == null ? '—' : '${formatOneDecimal(r.tkWh)} kWh'),
                      _DetailRow('Inverter status (irs)', r.irs ? 'Running' : 'Stopped'),
                      _DetailRow('Grid status (grs)', r.grs ? 'Connected' : 'Disconnected'),
                      _DetailRow('Phase status (pfs)', r.pfs ? 'Active' : 'Normal'),
                    ]),
                    if (r.undocumentedFields.isNotEmpty) ...[
                      const SizedBox(height: ClaroSpacing.lg),
                      _buildGroup(
                        context,
                        'Raw / System Data',
                        r.undocumentedFields.entries
                            .map((e) => _DetailRow(e.key, '${e.value}'))
                            .toList(),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context) {
    final p = context.palette;
    return Panel(
      padding: const EdgeInsets.all(ClaroSpacing.lg),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: ClaroRadius.md,
            child: Container(
              width: 96,
              height: 96,
              color: p.panelHigh,
              child: Image.asset('assets/images/device_hero_inverter.png', fit: BoxFit.cover),
            ),
          ),
          const SizedBox(width: ClaroSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(config.model, style: ClaroType.subtitle.copyWith(color: p.text, fontWeight: FontWeight.w600)),
                const SizedBox(height: ClaroSpacing.xs),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: ClaroSpacing.sm, vertical: 2),
                  decoration: BoxDecoration(
                    color: p.accentText.withValues(alpha: 0.14),
                    borderRadius: ClaroRadius.pill,
                  ),
                  child: Text('${config.panelCapacityKwp} kWp Panel Capacity', style: ClaroType.caption.copyWith(color: p.accentText)),
                ),
                const SizedBox(height: ClaroSpacing.xs),
                Text('sno: ${config.rmuSno}', style: ClaroType.caption.copyWith(color: p.textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroup(BuildContext context, String title, List<_DetailRow> rows) {
    final p = context.palette;
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
                if (i > 0) Divider(height: 1, color: p.border),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: ClaroSpacing.md),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 140,
                        child: Text(rows[i].label, style: ClaroType.body.copyWith(color: p.textMuted)),
                      ),
                      Expanded(
                        child: Text(
                          rows[i].value,
                          textAlign: TextAlign.end,
                          style: (rows[i].mono ? ClaroType.readoutSm : ClaroType.body)
                              .copyWith(color: p.text),
                        ),
                      ),
                      if (rows[i].onCopy != null) ...[
                        const SizedBox(width: ClaroSpacing.sm),
                        GestureDetector(
                          onTap: rows[i].onCopy,
                          child: Tooltip(
                            message: 'Copy ${rows[i].label}',
                            child: Icon(Icons.copy_rounded, size: 16, color: p.accentText),
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

class _DetailRow {
  const _DetailRow(this.label, this.value, {this.onCopy, this.mono = false});

  final String label;
  final String value;
  final VoidCallback? onCopy;
  final bool mono;
}
