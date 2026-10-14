import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../app/theme/claro_colors.dart';
import '../../app/theme/claro_dimens.dart';
import '../../app/theme/claro_type.dart';
import '../components/claro_primary_button.dart';
import 'camera_permission.dart';
import 'onboarding_widgets.dart';

/// Builds the live camera view. Replaceable in tests, which have no camera.
typedef ScannerViewBuilder = Widget Function(BuildContext context, ValueChanged<String> onCode);

/// Live QR scan for adding a device, ported from the Kotlin `QrScannerScreen`.
///
/// Scanning is fully on-device and offline. There is no QR-specific backend
/// call: the scanned text is simply the device identifier a farmer would
/// otherwise type by hand, so scanning is a shortcut to filling that field
/// accurately. A camera-permission screen comes first; denying it still leaves
/// the "enter manually" path.
///
/// Differences from the Kotlin version:
/// - The camera view comes from `mobile_scanner` (Kotlin used CameraX + ML Kit
///   with a manual refocus every 1.5 s); `mobile_scanner` handles autofocus.
/// - Permission is re-checked when the app returns to the foreground, so turning
///   the camera on in Settings takes effect without leaving this screen.
class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({
    super.key,
    required this.onScanned,
    required this.onEnterManually,
    required this.onClose,
    this.permission,
    this.scannerBuilder,
  });

  /// Tests set this to control camera permission for screens they don't
  /// construct directly (e.g. the scanner opened from the home screen).
  static CameraPermission? permissionOverride;

  final ValueChanged<String> onScanned;
  final VoidCallback onEnterManually;
  final VoidCallback onClose;
  /// Defaults to the device's real camera permission.
  final CameraPermission? permission;
  final ScannerViewBuilder? scannerBuilder;

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> with WidgetsBindingObserver {
  CameraPermission get _permission =>
      widget.permission ?? QrScannerScreen.permissionOverride ?? const DeviceCameraPermission();

  /// Null while the first check is running.
  CameraAccess? _access;
  bool _hasScanned = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _check();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _access != CameraAccess.granted) _check();
  }

  Future<void> _check() async {
    final access = await _permission.check();
    if (mounted) setState(() => _access = access);
  }

  Future<void> _request() async {
    final access = await _permission.request();
    if (mounted) setState(() => _access = access);
  }

  void _onCode(String value) {
    if (_hasScanned || value.trim().isEmpty) return;
    setState(() => _hasScanned = true);
    widget.onScanned(value);
  }

  @override
  Widget build(BuildContext context) {
    final access = _access;
    if (access == null) {
      return const Scaffold(backgroundColor: ClaroColors.ink);
    }
    if (access != CameraAccess.granted) {
      return _PermissionGate(
        permanentlyDenied: access == CameraAccess.permanentlyDenied,
        onRequest: _request,
        onOpenSettings: _permission.openSettings,
        onEnterManually: widget.onEnterManually,
        onClose: widget.onClose,
      );
    }

    final builder = widget.scannerBuilder ?? (context, onCode) => _CameraView(onCode: onCode);
    return Scaffold(
      backgroundColor: ClaroColors.ink,
      body: Stack(
        fit: StackFit.expand,
        children: [
          builder(context, _onCode),
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 48),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _ScanningIndicator(active: !_hasScanned),
                    const SizedBox(height: ClaroSpacing.lg),
                    EnterManuallyLink(onPressed: widget.onEnterManually),
                  ],
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.topLeft,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(ClaroSpacing.md),
                child: OnboardingCloseButton(onPressed: widget.onClose),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PermissionGate extends StatelessWidget {
  const _PermissionGate({
    required this.permanentlyDenied,
    required this.onRequest,
    required this.onOpenSettings,
    required this.onEnterManually,
    required this.onClose,
  });

  final bool permanentlyDenied;
  final VoidCallback onRequest;
  final VoidCallback onOpenSettings;
  final VoidCallback onEnterManually;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ClaroColors.ink,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(ClaroSpacing.xl),
          child: Column(
            children: [
              Align(alignment: Alignment.centerLeft, child: OnboardingCloseButton(onPressed: onClose)),
              const SizedBox(height: ClaroSpacing.huge),
              Text('Camera access needed', style: ClaroType.title.copyWith(color: ClaroColors.onInk)),
              const SizedBox(height: ClaroSpacing.sm),
              Text(
                permanentlyDenied
                    ? "Camera access was denied. You'll need to turn it on in Settings to scan your device's QR code — or enter the device ID by hand instead."
                    : "To scan the QR code on your device, Claro Pulse needs permission to use the camera. It's only used while this screen is open.",
                style: ClaroType.body.copyWith(color: ClaroColors.onInkMuted),
              ),
              const SizedBox(height: ClaroSpacing.xl),
              if (permanentlyDenied)
                ClaroPrimaryButton(text: 'Open Settings', onPressed: onOpenSettings)
              else
                ClaroPrimaryButton(text: 'Allow camera access', onPressed: onRequest),
              const SizedBox(height: ClaroSpacing.lg),
              EnterManuallyLink(onPressed: onEnterManually),
            ],
          ),
        ),
      ),
    );
  }
}

/// The live camera preview and barcode detection.
class _CameraView extends StatefulWidget {
  const _CameraView({required this.onCode});

  final ValueChanged<String> onCode;

  @override
  State<_CameraView> createState() => _CameraViewState();
}

class _CameraViewState extends State<_CameraView> {
  final MobileScannerController _controller = MobileScannerController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MobileScanner(
      controller: _controller,
      onDetect: (capture) {
        final barcodes = capture.barcodes;
        final raw = barcodes.isEmpty ? null : barcodes.first.rawValue;
        if (raw != null) widget.onCode(raw);
      },
    );
  }
}

/// "Scanning…" with a pulsing mint dot; "Scanned" with a solid dot once done.
class _ScanningIndicator extends StatefulWidget {
  const _ScanningIndicator({required this.active});

  final bool active;

  @override
  State<_ScanningIndicator> createState() => _ScanningIndicatorState();
}

class _ScanningIndicatorState extends State<_ScanningIndicator> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(_ScanningIndicator old) {
    super.didUpdateWidget(old);
    _sync();
  }

  void _sync() {
    if (widget.active) {
      if (!_pulse.isAnimating) _pulse.repeat(reverse: true);
    } else {
      _pulse.stop();
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: ClaroSpacing.lg, vertical: ClaroSpacing.sm),
      decoration: BoxDecoration(
        color: ClaroColors.ink.withValues(alpha: 0.6),
        borderRadius: ClaroRadius.pill,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _pulse,
            builder: (context, _) {
              // Alpha 0.35 → 1.0 while scanning, solid once scanned.
              final alpha = widget.active ? 0.35 + 0.65 * _pulse.value : 1.0;
              return Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: ClaroColors.mint.withValues(alpha: alpha),
                ),
              );
            },
          ),
          const SizedBox(width: ClaroSpacing.sm),
          Text(
            widget.active ? 'Scanning…' : 'Scanned',
            style: ClaroType.label.copyWith(color: ClaroColors.onInk),
          ),
        ],
      ),
    );
  }
}
