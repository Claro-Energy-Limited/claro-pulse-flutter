import 'package:flutter/material.dart';

import '../../app/theme/claro_colors.dart';
import '../../app/theme/claro_dimens.dart';
import '../../app/theme/claro_type.dart';
import '../components/claro_auth_background.dart';
import '../components/claro_data_readout.dart';
import '../components/claro_freshness_stamp.dart';
import '../components/claro_gauge_ring.dart';
import '../components/claro_line_chart.dart';
import '../components/claro_logo_mark.dart';
import '../components/claro_otp_row.dart';
import '../components/claro_powered_by.dart';
import '../components/claro_primary_button.dart';
import '../components/device_hero_card.dart';
import '../devices/device_kind.dart';
import '../icons/claro_icons.dart';

/// Developer page showing every shared component, to compare against the
/// Kotlin app. Reached from the temporary home screen; removed before release.
class ComponentGalleryScreen extends StatefulWidget {
  const ComponentGalleryScreen({super.key});

  @override
  State<ComponentGalleryScreen> createState() => _ComponentGalleryScreenState();
}

class _ComponentGalleryScreenState extends State<ComponentGalleryScreen> {
  String _otp = '';
  bool _running = true;
  int _gauge = 64;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: ClaroColors.ink, title: Text('Component gallery', style: ClaroType.title)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(ClaroSpacing.xl),
          children: [
            _section('Logo and powered-by on the sign-in background'),
            ClipRRect(
              borderRadius: ClaroRadius.lg,
              child: SizedBox(
                height: 220,
                child: ClaroAuthBackground(
                  child: Padding(
                    padding: const EdgeInsets.all(ClaroSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        ClaroLogoMark(),
                        Spacer(),
                        Center(child: ClaroPoweredBy()),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            _section('Device hero card (tap the switch to stop or start)'),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('Pump running', style: ClaroType.body),
              value: _running,
              onChanged: (v) => setState(() => _running = v),
            ),
            DeviceHeroCard(
              kind: DeviceKind.pump,
              isRunning: _running,
              callouts: const [
                HeroCallout(label: 'Solar', value: '5.4', unit: 'kW'),
                HeroCallout(label: 'Flow', value: '288', unit: 'L/min'),
                HeroCallout(label: 'Speed', value: '2880', unit: 'rpm'),
                HeroCallout(label: 'Head', value: noData, unit: 'm'),
              ],
              todaySummary: const [
                HeroMetric(label: 'Run time', value: '4.2', unit: 'hr'),
                HeroMetric(label: 'Energy', value: '12.6', unit: 'kWh'),
                HeroMetric(label: 'Water', value: '42,000', unit: 'L'),
              ],
            ),
            const SizedBox(height: ClaroSpacing.lg),
            const DeviceHeroCard(
              kind: DeviceKind.inverter,
              isRunning: false,
              comingSoon: true,
              callouts: [
                HeroCallout(label: 'Solar', value: noData, unit: 'kW'),
                HeroCallout(label: 'Battery', value: noData, unit: '%'),
                HeroCallout(label: 'Grid', value: noData, unit: 'kW'),
                HeroCallout(label: 'Load', value: noData, unit: 'kW'),
              ],
              todaySummary: [],
            ),
            _section('Readout and freshness stamp'),
            const ClaroDataReadout(
              label: 'Current power generation',
              value: '3.11',
              unit: 'kW',
              icon: SolarPanelIcon(size: 20, color: ClaroColors.mint),
            ),
            const SizedBox(height: ClaroSpacing.sm),
            const ClaroFreshnessStamp(text: 'Updated 2 min ago'),
            const SizedBox(height: ClaroSpacing.xs),
            const ClaroFreshnessStamp(text: 'Last seen 3 hr ago', isLive: false),
            _section('Line chart (with a gap where no data was reported)'),
            const ClaroLineChart(
              points: [2, 3.5, 4, null, null, 5, 6.2, 5.8, 4.1, 3],
              xLabels: ['6 AM', '9 AM', '12 PM', '3 PM', '6 PM'],
            ),
            const SizedBox(height: ClaroSpacing.lg),
            const ClaroLineChart(points: [null, null, null], xLabels: []),
            _section('OTP boxes (tap to type)'),
            ClaroOtpRow(value: _otp, onChanged: (v) => setState(() => _otp = v)),
            _section('Buttons'),
            ClaroPrimaryButton(text: 'Send code', onPressed: () {}),
            const SizedBox(height: ClaroSpacing.sm),
            ClaroPrimaryButton(text: 'Verifying', onPressed: () {}, loading: true),
            const SizedBox(height: ClaroSpacing.sm),
            ClaroPrimaryButton(text: 'Disabled', onPressed: () {}, enabled: false),
            _section('Gauge ring (light card; tap to change)'),
            GestureDetector(
              onTap: () => setState(() => _gauge = _gauge == 64 ? 92 : 64),
              child: Container(
                padding: const EdgeInsets.all(ClaroSpacing.lg),
                decoration: const BoxDecoration(color: ClaroColors.card, borderRadius: ClaroRadius.lg),
                child: Center(child: ClaroGaugeRing(percent: _gauge, label: 'Battery')),
              ),
            ),
            _section('Icons'),
            const Wrap(
              spacing: ClaroSpacing.lg,
              runSpacing: ClaroSpacing.lg,
              children: [
                SolarPanelIcon(size: 32),
                BatteryIcon(size: 32),
                LoadIcon(size: 32),
                ClockIcon(size: 32),
                WaterDropIcon(size: 32),
                EvseIcon(size: 32),
                GridTowerIcon(size: 32),
                NavHomeIcon(size: 28, color: ClaroColors.mint),
                NavAnalyticsIcon(size: 28),
                NavGridIcon(size: 28),
                NavWalletIcon(size: 28),
                NavProfileIcon(size: 28),
              ],
            ),
            const SizedBox(height: ClaroSpacing.xxxl),
          ],
        ),
      ),
    );
  }

  Widget _section(String title) => Padding(
        padding: const EdgeInsets.only(top: ClaroSpacing.xxl, bottom: ClaroSpacing.md),
        child: Text(title, style: ClaroType.label.copyWith(color: context.textSecondary)),
      );
}
