import 'package:flutter/material.dart';

import '../../app/theme/claro_colors.dart';
import '../../app/theme/claro_dimens.dart';
import '../../app/theme/claro_type.dart';
import '../../core/api/models/device_models.dart';
import '../components/claro_primary_button.dart';
import '../icons/claro_icons.dart';
import 'device_kind.dart';

/// The Devices tab, ported from the Kotlin `DevicesTabContent`: every device on
/// the account, each opening its detail screen.
///
/// Loading, error and empty are deliberately separate states: a slow network
/// must never look like owning zero devices. `HomeScreen` owns the request;
/// this widget only renders what it is given.
class DevicesTab extends StatelessWidget {
  const DevicesTab({
    super.key,
    required this.devices,
    required this.isLoading,
    required this.error,
    required this.onRetry,
    required this.onDeviceTap,
    required this.onAddDevice,
  });

  final List<MyDevice>? devices;
  final bool isLoading;
  final String? error;
  final VoidCallback onRetry;
  final ValueChanged<MyDevice> onDeviceTap;
  final VoidCallback onAddDevice;

  @override
  Widget build(BuildContext context) {
    final devices = this.devices;
    final error = this.error;
    final Widget body;
    if (isLoading && devices == null) {
      body = const Center(child: CircularProgressIndicator(color: ClaroColors.mint));
    } else if (error != null && devices == null) {
      body = _CenteredMessage(
        title: "Couldn't load your devices",
        message: error,
        buttonText: 'Try again',
        onPressed: onRetry,
      );
    } else if (devices == null || devices.isEmpty) {
      body = _CenteredMessage(
        title: 'No devices yet',
        message: 'Scan the QR code on your device to add it.',
        buttonText: 'Add a device',
        onPressed: onAddDevice,
      );
    } else {
      body = ListView.separated(
        padding: const EdgeInsets.only(bottom: ClaroSpacing.lg),
        itemCount: devices.length,
        separatorBuilder: (_, _) => const SizedBox(height: ClaroSpacing.md),
        itemBuilder: (_, i) => _DeviceRow(device: devices[i], onTap: () => onDeviceTap(devices[i])),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: ClaroSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: ClaroSpacing.lg),
          Row(
            children: [
              Expanded(child: Text('Your devices', style: ClaroType.title.copyWith(color: ClaroColors.onInk))),
              _AddButton(onPressed: onAddDevice),
            ],
          ),
          const SizedBox(height: ClaroSpacing.lg),
          Expanded(child: body),
        ],
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  const _AddButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Add device',
      child: Material(
        color: ClaroColors.mint,
        borderRadius: ClaroRadius.md,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: const SizedBox.square(
            dimension: 36,
            child: Icon(Icons.add, size: 20, color: ClaroColors.ink),
          ),
        ),
      ),
    );
  }
}

class _DeviceRow extends StatelessWidget {
  const _DeviceRow({required this.device, required this.onTap});

  final MyDevice device;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isInverter = DeviceKind.from(device.kind) == DeviceKind.inverter;
    return Material(
      color: ClaroColors.inkPanel,
      shape: const RoundedRectangleBorder(
        borderRadius: ClaroRadius.lg,
        side: BorderSide(color: ClaroColors.borderDark),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(ClaroSpacing.lg),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: ClaroColors.inkPanelHigh, borderRadius: ClaroRadius.md),
                alignment: Alignment.center,
                child: isInverter
                    ? const BatteryIcon(size: 20, color: ClaroColors.mint)
                    : const WaterDropIcon(size: 20, color: ClaroColors.mint),
              ),
              const SizedBox(width: ClaroSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(device.deviceUid, style: ClaroType.subtitle.copyWith(color: ClaroColors.onInk)),
                    const SizedBox(height: 2),
                    Text(
                      device.addressLine ?? 'Serial ${device.serialNo ?? device.imei}',
                      style: ClaroType.caption.copyWith(color: ClaroColors.onInkMuted),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward, size: 18, color: ClaroColors.onInkMuted),
            ],
          ),
        ),
      ),
    );
  }
}

class _CenteredMessage extends StatelessWidget {
  const _CenteredMessage({
    required this.title,
    required this.message,
    required this.buttonText,
    required this.onPressed,
  });

  final String title;
  final String message;
  final String buttonText;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: ClaroType.title.copyWith(color: ClaroColors.onInk), textAlign: TextAlign.center),
            const SizedBox(height: ClaroSpacing.xs),
            Text(
              message,
              style: ClaroType.body.copyWith(color: ClaroColors.onInkMuted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: ClaroSpacing.lg),
            ClaroPrimaryButton(text: buttonText, onPressed: onPressed),
          ],
        ),
      ),
    );
  }
}
