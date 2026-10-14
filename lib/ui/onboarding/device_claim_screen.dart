import 'package:flutter/material.dart';

import '../../app/theme/claro_colors.dart';
import '../../app/theme/claro_dimens.dart';
import '../../app/theme/claro_type.dart';
import '../../core/api/api_exception.dart';
import '../../core/api/claro_pulse_api.dart';
import '../components/claro_primary_button.dart';
import 'onboarding_widgets.dart';

/// Confirms and submits a device claim, ported from the Kotlin `DeviceClaimScreen`.
///
/// `proofReference` is required by the server, but a QR code or typed IMEI
/// doesn't carry one, so it is filled with a fixed, honest note saying which
/// path produced the value: the reviewing admin reads it when approving.
///
/// A claim does NOT attach the device straight away: it stays PENDING until the
/// utility's team approves it. So the success state says "submitted for review",
/// never "device added".
class DeviceClaimScreen extends StatefulWidget {
  const DeviceClaimScreen({
    super.key,
    required this.scannedValue,
    required this.enteredManually,
    required this.api,
    required this.onSubmitted,
    required this.onBack,
  });

  final String scannedValue;
  final bool enteredManually;
  final ClaroPulseApi api;
  final VoidCallback onSubmitted;
  final VoidCallback onBack;

  static const proofManual = 'Entered device ID manually via Claro Pulse app';
  static const proofScanned = 'Scanned device QR code via Claro Pulse app';

  @override
  State<DeviceClaimScreen> createState() => _DeviceClaimScreenState();
}

class _DeviceClaimScreenState extends State<DeviceClaimScreen> {
  bool _submitting = false;
  bool _submitted = false;
  String? _error;

  Future<void> _submit() async {
    if (_submitting) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await widget.api.submitDeviceClaim(
        deviceIdentifier: widget.scannedValue,
        proofReference: widget.enteredManually ? DeviceClaimScreen.proofManual : DeviceClaimScreen.proofScanned,
      );
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _submitted = true;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = e.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ClaroColors.ink,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(ClaroSpacing.xl),
          child: _submitted ? _SubmittedState(onDone: widget.onSubmitted) : _confirm(),
        ),
      ),
    );
  }

  Widget _confirm() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OnboardingBackButton(onPressed: widget.onBack),
          const SizedBox(height: ClaroSpacing.xxl),
          Text('Add this device?', style: ClaroType.displayLg.copyWith(color: ClaroColors.onInk)),
          const SizedBox(height: ClaroSpacing.sm),
          Text(
            "We'll send this to your utility's team for a quick review before it shows up on your dashboard.",
            style: ClaroType.body.copyWith(color: ClaroColors.onInkMuted),
          ),
          const SizedBox(height: ClaroSpacing.xl),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(ClaroSpacing.lg),
            decoration: BoxDecoration(
              color: ClaroColors.inkPanel,
              borderRadius: ClaroRadius.md,
              border: Border.all(color: ClaroColors.borderDark),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Device ID', style: ClaroType.caption.copyWith(color: ClaroColors.onInkMuted)),
                const SizedBox(height: 4),
                Text(widget.scannedValue, style: ClaroType.readout.copyWith(color: ClaroColors.onInk)),
              ],
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: ClaroSpacing.md),
            Text(_error!, style: ClaroType.caption.copyWith(color: ClaroColors.fault)),
          ],
          const SizedBox(height: ClaroSpacing.xl),
          ClaroPrimaryButton(text: 'Submit for review', onPressed: _submit, loading: _submitting),
        ],
      ),
    );
  }
}

class _SubmittedState extends StatelessWidget {
  const _SubmittedState({required this.onDone});

  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: ClaroColors.mintDeep.withValues(alpha: 0.25),
              ),
              child: const Icon(Icons.check, color: ClaroColors.mint, size: 36),
            ),
            const SizedBox(height: ClaroSpacing.lg),
            Text('Submitted for review', style: ClaroType.title.copyWith(color: ClaroColors.onInk)),
            const SizedBox(height: ClaroSpacing.xs),
            Text(
              "We'll let you know once it's approved and showing live data.",
              textAlign: TextAlign.center,
              style: ClaroType.body.copyWith(color: ClaroColors.onInkMuted),
            ),
            const SizedBox(height: ClaroSpacing.xl),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: ClaroSpacing.xl),
              child: ClaroPrimaryButton(text: 'Done', onPressed: onDone),
            ),
          ],
        ),
      ),
    );
  }
}
