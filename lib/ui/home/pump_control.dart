import 'package:flutter/material.dart';

import '../../app/theme/claro_colors.dart';
import '../../app/theme/claro_dimens.dart';
import '../../app/theme/claro_type.dart';
import '../../core/api/models/device_models.dart';
import '../../core/api/models/pump_models.dart';
import '../components/claro_primary_button.dart';
import 'pump_state.dart';

/// The big Start / Stop button on Home.
///
/// It never flips state on its own: after a tap it shows "Starting…" or
/// "Stopping…" until the pump's own status confirms the change.
class PumpControlButton extends StatelessWidget {
  const PumpControlButton({super.key, required this.visual, required this.onStart, required this.onStop});

  final PumpVisual visual;
  final VoidCallback onStart;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    final pending = visual == PumpVisual.starting || visual == PumpVisual.stopping;
    final running = visual == PumpVisual.running;

    final Color background;
    final Color foreground;
    final Color border;
    if (pending) {
      background = ClaroColors.warn.withValues(alpha: 0.12);
      foreground = ClaroColors.warn;
      border = ClaroColors.warn.withValues(alpha: 0.4);
    } else if (running) {
      background = ClaroColors.fault.withValues(alpha: 0.12);
      foreground = ClaroColors.fault;
      border = ClaroColors.fault.withValues(alpha: 0.45);
    } else {
      background = ClaroColors.mint;
      foreground = ClaroColors.ink;
      border = ClaroColors.mint;
    }

    final label = switch (visual) {
      PumpVisual.starting => 'Starting pump…',
      PumpVisual.stopping => 'Stopping pump…',
      PumpVisual.running => 'Stop pump',
      _ => 'Start pump',
    };

    return Semantics(
      button: true,
      enabled: !pending,
      child: Material(
        color: background,
        borderRadius: ClaroRadius.pill,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: pending ? null : (running ? onStop : onStart),
          child: Container(
            height: 60,
            decoration: BoxDecoration(borderRadius: ClaroRadius.pill, border: Border.all(color: border)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (pending)
                  SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: foreground),
                  )
                else
                  Icon(Icons.power_settings_new_rounded, color: foreground, size: 22),
                const SizedBox(width: ClaroSpacing.sm),
                Flexible(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: ClaroType.subtitle.copyWith(color: foreground, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Asks the farmer to confirm a start or stop. Returns true if confirmed.
///
/// Starting shows the safety checks the app knows about; any failed check
/// disables the button and says why, in plain words.
Future<bool> confirmPumpCommand(
  BuildContext context, {
  required PumpCommand command,
  required String deviceName,
  required DeviceStatus? status,
  required bool isDemo,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    backgroundColor: context.panel,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: ClaroRadius.sheet),
    builder: (context) => _PumpCommandSheet(
      command: command,
      deviceName: deviceName,
      status: status,
      isDemo: isDemo,
    ),
  );
  return result ?? false;
}

class _PumpCommandSheet extends StatelessWidget {
  const _PumpCommandSheet({
    required this.command,
    required this.deviceName,
    required this.status,
    required this.isDemo,
  });

  final PumpCommand command;
  final String deviceName;
  final DeviceStatus? status;
  final bool isDemo;

  @override
  Widget build(BuildContext context) {
    final starting = command == PumpCommand.start;
    final s = status;
    final checks = starting
        ? <(String, bool)>[
            ('Pump is online', s != null && s.connectionStatus == 'ONLINE'),
            ('Enough water in the well', s != null && !s.protections.dryRun && !s.protections.waterLevelLow),
            ('No faults reported', s != null && s.faultText == null),
          ]
        : const <(String, bool)>[];
    final blocked = starting ? startBlockedReason(s) : null;
    final tint = starting ? ClaroColors.mint : ClaroColors.fault;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(ClaroSpacing.xl, ClaroSpacing.md, ClaroSpacing.xl, ClaroSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _SheetHandle(),
            const SizedBox(height: ClaroSpacing.lg),
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: tint.withValues(alpha: 0.14)),
                  child: Icon(Icons.power_settings_new_rounded, color: tint),
                ),
                const SizedBox(width: ClaroSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        starting ? 'Start the pump?' : 'Stop the pump?',
                        style: ClaroType.title.copyWith(color: context.textPrimary),
                      ),
                      Text(deviceName, style: ClaroType.caption.copyWith(color: context.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: ClaroSpacing.lg),
            if (starting) ...[
              for (final (label, ok) in checks)
                Padding(
                  padding: const EdgeInsets.only(bottom: ClaroSpacing.sm),
                  child: Row(
                    children: [
                      Icon(
                        ok ? Icons.check_circle_rounded : Icons.cancel_rounded,
                        size: 20,
                        color: ok ? context.brandMint : ClaroColors.fault,
                      ),
                      const SizedBox(width: ClaroSpacing.sm),
                      Expanded(child: Text(label, style: ClaroType.body.copyWith(color: context.textPrimary))),
                    ],
                  ),
                ),
              const SizedBox(height: ClaroSpacing.sm),
              Text(
                blocked ?? 'Make sure no one is working on or near the pump.',
                style: ClaroType.caption.copyWith(color: blocked == null ? context.textSecondary : ClaroColors.fault),
              ),
            ] else
              Text(
                'Water will stop flowing until you start the pump again.',
                style: ClaroType.body.copyWith(color: context.textSecondary),
              ),
            if (isDemo) ...[
              const SizedBox(height: ClaroSpacing.md),
              Text(
                'Demo mode: no real pump is controlled.',
                style: ClaroType.caption.copyWith(color: ClaroColors.warn),
              ),
            ],
            const SizedBox(height: ClaroSpacing.xl),
            if (starting)
              ClaroPrimaryButton(
                text: 'Start pump',
                enabled: blocked == null,
                onPressed: () => Navigator.of(context).pop(true),
              )
            else
              _DangerButton(text: 'Stop pump', onPressed: () => Navigator.of(context).pop(true)),
            const SizedBox(height: ClaroSpacing.sm),
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancel', style: ClaroType.subtitle.copyWith(color: context.textSecondary)),
            ),
          ],
        ),
      ),
    );
  }
}

class _DangerButton extends StatelessWidget {
  const _DangerButton({required this.text, required this.onPressed});

  final String text;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ClaroColors.fault,
      borderRadius: ClaroRadius.md,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: SizedBox(
          height: 56,
          child: Center(child: Text(text, style: ClaroType.subtitle.copyWith(color: ClaroColors.onInk))),
        ),
      ),
    );
  }
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: const BoxDecoration(color: ClaroColors.borderDark, borderRadius: ClaroRadius.pill),
      ),
    );
  }
}

// ── Bluetooth (simulated for now) ──────────────────────────────────────────

enum BluetoothLink { off, searching, connected }

/// Explains Bluetooth control and lets the farmer connect or disconnect.
/// The link state lives in the home screen; this sheet follows it live.
Future<void> showBluetoothSheet(
  BuildContext context, {
  required ValueNotifier<BluetoothLink> link,
  required String deviceName,
  required VoidCallback onConnect,
  required VoidCallback onDisconnect,
  required bool isDemo,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: context.panel,
    shape: const RoundedRectangleBorder(borderRadius: ClaroRadius.sheet),
    builder: (context) => SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(ClaroSpacing.xl, ClaroSpacing.md, ClaroSpacing.xl, ClaroSpacing.xl),
        child: ValueListenableBuilder<BluetoothLink>(
          valueListenable: link,
          builder: (context, state, _) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _SheetHandle(),
              const SizedBox(height: ClaroSpacing.lg),
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: context.brandMint.withValues(alpha: 0.14),
                    ),
                    child: Icon(
                      state == BluetoothLink.connected ? Icons.bluetooth_connected_rounded : Icons.bluetooth_rounded,
                      color: context.brandMint,
                    ),
                  ),
                  const SizedBox(width: ClaroSpacing.md),
                  Expanded(
                    child: Text('Bluetooth control', style: ClaroType.title.copyWith(color: context.textPrimary)),
                  ),
                ],
              ),
              const SizedBox(height: ClaroSpacing.md),
              Text(
                "Control your pump when you're standing next to it, even without mobile internet.",
                style: ClaroType.body.copyWith(color: context.textSecondary),
              ),
              const SizedBox(height: ClaroSpacing.xl),
              switch (state) {
                BluetoothLink.off => ClaroPrimaryButton(text: 'Connect to $deviceName', onPressed: onConnect),
                BluetoothLink.searching => Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: context.brandMint),
                      ),
                      const SizedBox(width: ClaroSpacing.md),
                      Flexible(
                        child: Text(
                          'Looking for your pump nearby…',
                          style: ClaroType.body.copyWith(color: context.textPrimary),
                        ),
                      ),
                    ],
                  ),
                BluetoothLink.connected => Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_rounded, color: context.brandMint, size: 20),
                          const SizedBox(width: ClaroSpacing.sm),
                          Flexible(
                            child: Text(
                              'Connected to $deviceName',
                              style: ClaroType.body.copyWith(color: context.textPrimary),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: ClaroSpacing.md),
                      TextButton(
                        onPressed: onDisconnect,
                        child: Text('Disconnect', style: ClaroType.subtitle.copyWith(color: ClaroColors.fault)),
                      ),
                    ],
                  ),
              },
              if (isDemo) ...[
                const SizedBox(height: ClaroSpacing.md),
                Text(
                  'Demo mode: Bluetooth is simulated.',
                  textAlign: TextAlign.center,
                  style: ClaroType.caption.copyWith(color: ClaroColors.warn),
                ),
              ],
            ],
          ),
        ),
      ),
    ),
  );
}
