import 'package:flutter/material.dart';

import '../../app/theme/claro_colors.dart';
import '../../app/theme/claro_dimens.dart';
import '../../app/theme/claro_type.dart';
import '../../core/api/models/device_models.dart';
import '../components/claro_primary_button.dart';
import '../devices/device_kind.dart';

// TEMPORARY. Each widget here is replaced by the real screen in a later phase:
//   HomeTabPlaceholder     → phase 5 (device pager, flow card, weather)
//   DevicesTabPlaceholder  → phase 4 (device list)
//   QrScanPlaceholder, OverlayPlaceholder → phases 4 and 6
// They already receive the same data the real screens will, so the home
// screen's loading logic can be checked now.

Widget _note(String text) => Padding(
      padding: const EdgeInsets.only(top: ClaroSpacing.lg),
      child: Text(text, style: ClaroType.caption.copyWith(color: ClaroColors.warn)),
    );

Widget _panel({required Widget child}) => Container(
      padding: const EdgeInsets.all(ClaroSpacing.lg),
      decoration: BoxDecoration(
        color: ClaroColors.inkPanel,
        borderRadius: ClaroRadius.lg,
        border: Border.all(color: ClaroColors.borderDark),
      ),
      child: child,
    );

Widget _errorWithRetry(String message, VoidCallback onRetry) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(message, style: ClaroType.body.copyWith(color: ClaroColors.fault)),
        TextButton(onPressed: onRetry, child: const Text('Try again')),
      ],
    );

const Widget _spinner = Padding(
  padding: EdgeInsets.all(ClaroSpacing.xl),
  child: Center(child: CircularProgressIndicator(color: ClaroColors.mint)),
);

String _kindLabel(MyDevice d) => DeviceKind.from(d.kind) == DeviceKind.inverter ? 'Inverter' : 'Pump';

class HomeTabPlaceholder extends StatefulWidget {
  const HomeTabPlaceholder({
    super.key,
    required this.devices,
    required this.devicesError,
    required this.claims,
    required this.statusById,
    required this.statusErrorById,
    required this.onRetryDevices,
    required this.onPageSettled,
    required this.onRetryStatus,
    required this.onAddDevice,
  });

  final List<MyDevice>? devices;
  final String? devicesError;
  final List<DeviceClaim>? claims;
  final Map<String, DeviceStatus> statusById;
  final Map<String, String> statusErrorById;
  final VoidCallback onRetryDevices;
  final ValueChanged<int> onPageSettled;
  final ValueChanged<String> onRetryStatus;
  final VoidCallback onAddDevice;

  @override
  State<HomeTabPlaceholder> createState() => _HomeTabPlaceholderState();
}

class _HomeTabPlaceholderState extends State<HomeTabPlaceholder> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final devices = widget.devices;
    if (widget.devicesError != null) return _errorWithRetry(widget.devicesError!, widget.onRetryDevices);
    if (devices == null) return _spinner;

    if (devices.isEmpty) {
      final pending = widget.claims?.where((c) => c.status == 'PENDING').length ?? 0;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('No devices yet', style: ClaroType.title),
          if (pending > 0)
            Text('$pending claim(s) waiting for approval.', style: ClaroType.body.copyWith(color: ClaroColors.mint)),
          const SizedBox(height: ClaroSpacing.lg),
          ClaroPrimaryButton(text: 'Add a device', onPressed: widget.onAddDevice),
          _note('Full Home tab arrives in phase 5.'),
        ],
      );
    }

    final device = devices[_index.clamp(0, devices.length - 1)];
    final status = widget.statusById[device.deviceId];
    final error = widget.statusErrorById[device.deviceId];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(device.deviceUid, style: ClaroType.subtitle)),
                  Text(_kindLabel(device), style: ClaroType.label.copyWith(color: ClaroColors.mint)),
                ],
              ),
              const SizedBox(height: ClaroSpacing.md),
              if (error != null)
                _errorWithRetry(error, () => widget.onRetryStatus(device.deviceId))
              else if (status == null)
                const Center(child: CircularProgressIndicator(color: ClaroColors.mint))
              else ...[
                Text('${status.runStatus} · ${status.connectionStatus}', style: ClaroType.readout),
                if (status.live.flowRateLpm != null)
                  Text('Flow ${status.live.flowRateLpm} L/min', style: ClaroType.readoutSm),
                if (status.live.solarPowerKw != null)
                  Text('Solar ${status.live.solarPowerKw} kW', style: ClaroType.readoutSm),
              ],
            ],
          ),
        ),
        if (devices.length > 1)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: _index > 0 ? () => _show(_index - 1) : null,
                child: const Text('‹ Previous'),
              ),
              Text('${_index + 1} of ${devices.length}', style: ClaroType.caption),
              TextButton(
                onPressed: _index < devices.length - 1 ? () => _show(_index + 1) : null,
                child: const Text('Next ›'),
              ),
            ],
          ),
        _note('Full Home tab (swipeable device cards, flow card, weather) arrives in phase 5.'),
      ],
    );
  }

  void _show(int index) {
    setState(() => _index = index);
    widget.onPageSettled(index);
  }
}

class DevicesTabPlaceholder extends StatelessWidget {
  const DevicesTabPlaceholder({
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
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: ClaroSpacing.xl),
      children: [
        const SizedBox(height: ClaroSpacing.lg),
        Text('Devices', style: ClaroType.title),
        const SizedBox(height: ClaroSpacing.lg),
        if (isLoading)
          _spinner
        else if (error != null)
          _errorWithRetry(error!, onRetry)
        else
          for (final d in devices ?? const <MyDevice>[])
            Padding(
              padding: const EdgeInsets.only(bottom: ClaroSpacing.sm),
              child: GestureDetector(
                onTap: () => onDeviceTap(d),
                child: _panel(
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(d.deviceUid, style: ClaroType.subtitle),
                            Text(
                              d.addressLine ?? '',
                              style: ClaroType.caption.copyWith(color: ClaroColors.onInkMuted),
                            ),
                          ],
                        ),
                      ),
                      Text(_kindLabel(d), style: ClaroType.label.copyWith(color: ClaroColors.mint)),
                    ],
                  ),
                ),
              ),
            ),
        const SizedBox(height: ClaroSpacing.lg),
        ClaroPrimaryButton(text: 'Add a device', onPressed: onAddDevice),
        _note('Full Devices tab arrives in phase 4.'),
      ],
    );
  }
}

class QrScanPlaceholder extends StatelessWidget {
  const QrScanPlaceholder({super.key, required this.onEnterManually, required this.onClose});

  final VoidCallback onEnterManually;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return OverlayPlaceholder(
      title: 'Scan device QR',
      message: 'QR scanning arrives in phase 6.',
      onBack: onClose,
      action: ClaroPrimaryButton(text: 'Enter ID manually', onPressed: onEnterManually),
    );
  }
}

class OverlayPlaceholder extends StatelessWidget {
  const OverlayPlaceholder({
    super.key,
    required this.title,
    required this.message,
    required this.onBack,
    this.action,
  });

  final String title;
  final String message;
  final VoidCallback onBack;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ClaroColors.ink,
      appBar: AppBar(
        backgroundColor: ClaroColors.ink,
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: onBack, tooltip: 'Back'),
        title: Text(title, style: ClaroType.title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(ClaroSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(message, style: ClaroType.body.copyWith(color: ClaroColors.warn)),
            if (action != null) ...[const SizedBox(height: ClaroSpacing.xl), action!],
          ],
        ),
      ),
    );
  }
}
