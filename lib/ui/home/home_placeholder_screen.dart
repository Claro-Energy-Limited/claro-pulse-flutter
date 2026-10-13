import 'package:flutter/material.dart';

import '../../app/theme/claro_colors.dart';
import '../../app/theme/claro_dimens.dart';
import '../../app/theme/claro_type.dart';
import '../../core/api/models/device_models.dart';
import '../../core/services.dart';
import '../components/claro_logo_mark.dart';
import '../components/claro_primary_button.dart';
import '../dev/component_gallery_screen.dart';
import '../devices/device_kind.dart';

/// Temporary home screen until phase 3 ports the real one. Confirms sign-in
/// worked and that the API (real or mock) returns this account's devices.
class HomePlaceholderScreen extends StatefulWidget {
  const HomePlaceholderScreen({super.key, required this.services, required this.onSignOut});

  final AppServices services;
  final VoidCallback onSignOut;

  @override
  State<HomePlaceholderScreen> createState() => _HomePlaceholderScreenState();
}

class _HomePlaceholderScreenState extends State<HomePlaceholderScreen> {
  late Future<List<MyDevice>> _devices = widget.services.api.listMyDevices();

  @override
  Widget build(BuildContext context) {
    final phone = widget.services.tokenStore.phone;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(ClaroSpacing.xl),
          children: [
            const Align(alignment: Alignment.centerLeft, child: ClaroLogoMark()),
            const SizedBox(height: ClaroSpacing.xl),
            if (widget.services.isMock) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: ClaroSpacing.md, vertical: ClaroSpacing.xs),
                  decoration: BoxDecoration(
                    color: ClaroColors.warn.withValues(alpha: 0.15),
                    borderRadius: ClaroRadius.pill,
                  ),
                  child: Text('MOCK DATA', style: ClaroType.label.copyWith(color: ClaroColors.warn)),
                ),
              ),
              const SizedBox(height: ClaroSpacing.md),
            ],
            Text('Signed in', style: ClaroType.displayLg),
            const SizedBox(height: ClaroSpacing.xs),
            Text(
              phone == null ? 'Session restored' : '+91 $phone',
              style: ClaroType.body.copyWith(color: ClaroColors.onInkMuted),
            ),
            const SizedBox(height: ClaroSpacing.sm),
            Text(
              'The real home screen arrives in phase 3.',
              style: ClaroType.body.copyWith(color: ClaroColors.onInkMuted),
            ),
            const SizedBox(height: ClaroSpacing.xl),
            Text('Your devices', style: ClaroType.title),
            const SizedBox(height: ClaroSpacing.md),
            FutureBuilder<List<MyDevice>>(
              future: _devices,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Padding(
                    padding: EdgeInsets.all(ClaroSpacing.lg),
                    child: Center(child: CircularProgressIndicator(color: ClaroColors.mint)),
                  );
                }
                if (snapshot.hasError) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${snapshot.error}', style: ClaroType.body.copyWith(color: ClaroColors.fault)),
                      TextButton(
                        onPressed: () => setState(() => _devices = widget.services.api.listMyDevices()),
                        child: const Text('Try again'),
                      ),
                    ],
                  );
                }
                final devices = snapshot.data!;
                if (devices.isEmpty) {
                  return Text('No devices yet.', style: ClaroType.body.copyWith(color: ClaroColors.onInkMuted));
                }
                return Column(
                  children: [
                    for (final d in devices)
                      Container(
                        margin: const EdgeInsets.only(bottom: ClaroSpacing.sm),
                        padding: const EdgeInsets.all(ClaroSpacing.lg),
                        decoration: BoxDecoration(color: ClaroColors.inkPanel, borderRadius: ClaroRadius.md),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(d.deviceUid, style: ClaroType.subtitle),
                                  Text(
                                    d.addressLine ?? 'No address',
                                    style: ClaroType.caption.copyWith(color: ClaroColors.onInkMuted),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              DeviceKind.from(d.kind) == DeviceKind.inverter ? 'Inverter' : 'Pump',
                              style: ClaroType.label.copyWith(color: ClaroColors.mint),
                            ),
                          ],
                        ),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: ClaroSpacing.xl),
            ClaroPrimaryButton(
              text: 'Component gallery',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const ComponentGalleryScreen()),
              ),
            ),
            const SizedBox(height: ClaroSpacing.md),
            Center(
              child: TextButton(
                onPressed: widget.onSignOut,
                child: Text('Sign out', style: ClaroType.subtitle.copyWith(color: ClaroColors.fault)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
