import 'package:flutter/material.dart';

import 'app/theme/claro_colors.dart';
import 'app/theme/claro_dimens.dart';
import 'app/theme/claro_theme.dart';
import 'app/theme/claro_type.dart';
import 'core/config/api_config.dart';
import 'core/services.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final services = await AppServices.create();
  runApp(ClaroPulseApp(signedIn: services.tokenStore.isSignedIn));
}

class ClaroPulseApp extends StatelessWidget {
  const ClaroPulseApp({super.key, required this.signedIn});

  final bool signedIn;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Claro Pulse',
      debugShowCheckedModeBanner: false,
      theme: ClaroTheme.dark,
      home: ThemeCheckScreen(signedIn: signedIn),
    );
  }
}

/// Temporary screen to confirm theme, fonts and assets are wired correctly.
/// Replace it with the real sign-in and home screens.
class ThemeCheckScreen extends StatelessWidget {
  const ThemeCheckScreen({super.key, required this.signedIn});

  final bool signedIn;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(ClaroSpacing.xl),
          children: [
            Text('Claro Pulse', style: ClaroType.displayLg),
            const SizedBox(height: ClaroSpacing.sm),
            Text(
              'Theme check: Plus Jakarta Sans for text, JetBrains Mono for numbers.',
              style: ClaroType.body.copyWith(color: ClaroColors.onInkMuted),
            ),
            const SizedBox(height: ClaroSpacing.xl),
            Container(
              padding: const EdgeInsets.all(ClaroSpacing.lg),
              decoration: BoxDecoration(
                color: ClaroColors.inkPanel,
                borderRadius: ClaroRadius.lg,
                border: Border.all(color: ClaroColors.borderDark),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Flow rate', style: ClaroType.label.copyWith(color: ClaroColors.onInkMuted)),
                  const SizedBox(height: ClaroSpacing.xs),
                  Text('288.0 L/min', style: ClaroType.readoutXl.copyWith(color: ClaroColors.mint)),
                  const SizedBox(height: ClaroSpacing.md),
                  const Row(
                    children: [
                      _Pill(label: 'Online', color: ClaroColors.mint),
                      SizedBox(width: ClaroSpacing.sm),
                      _Pill(label: 'Dry run', color: ClaroColors.fault),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: ClaroSpacing.xl),
            ClipRRect(
              borderRadius: ClaroRadius.lg,
              child: Image.asset('assets/images/device_hero_pump.png', height: 180, fit: BoxFit.cover),
            ),
            const SizedBox(height: ClaroSpacing.xl),
            FilledButton(onPressed: () {}, child: const Text('Primary button')),
            const SizedBox(height: ClaroSpacing.xl),
            Text('Signed in: ${signedIn ? 'yes' : 'no'}', style: ClaroType.readoutSm),
            Text('API: $apiBaseUrl', style: ClaroType.readoutSm.copyWith(color: ClaroColors.onInkMuted)),
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: ClaroSpacing.md, vertical: ClaroSpacing.xs),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: ClaroRadius.pill,
      ),
      child: Text(label, style: ClaroType.label.copyWith(color: color)),
    );
  }
}
