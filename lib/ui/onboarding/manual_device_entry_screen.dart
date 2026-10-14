import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme/claro_colors.dart';
import '../../app/theme/claro_dimens.dart';
import '../../app/theme/claro_type.dart';
import '../components/claro_primary_button.dart';
import 'onboarding_widgets.dart';

const _maxDigits = 16;
const _minDigits = 6;

/// Manual fallback for the QR scanner, ported from the Kotlin
/// `ManualDeviceEntryScreen`. Reached from "enter manually" on the scanner or
/// its permission screen: a farmer who denies camera access must still be able
/// to add a device.
///
/// Digits only, at most 16 (an IMEI is 15, plus room for a long serial).
/// Beyond that it only checks the value isn't trivially short; the backend
/// decides whether an identifier is a real device.
class ManualDeviceEntryScreen extends StatefulWidget {
  const ManualDeviceEntryScreen({super.key, required this.onSubmit, required this.onBack});

  final ValueChanged<String> onSubmit;
  final VoidCallback onBack;

  @override
  State<ManualDeviceEntryScreen> createState() => _ManualDeviceEntryScreenState();
}

class _ManualDeviceEntryScreenState extends State<ManualDeviceEntryScreen> {
  final _controller = TextEditingController();
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  bool get _valid => _controller.text.length >= _minDigits;

  void _submit() {
    if (_valid) widget.onSubmit(_controller.text);
  }

  @override
  Widget build(BuildContext context) {
    final focused = _focus.hasFocus;
    return Scaffold(
      backgroundColor: context.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(ClaroSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              OnboardingBackButton(onPressed: widget.onBack),
              const SizedBox(height: ClaroSpacing.xxl),
              Text('Enter device ID', style: ClaroType.displayLg.copyWith(color: context.textPrimary)),
              const SizedBox(height: ClaroSpacing.sm),
              Text(
                'Type the IMEI number printed on your device or its box.',
                style: ClaroType.body.copyWith(color: context.textSecondary),
              ),
              const SizedBox(height: ClaroSpacing.xl),
              AnimatedContainer(
                duration: ClaroMotion.fast,
                height: 56,
                padding: const EdgeInsets.symmetric(horizontal: ClaroSpacing.lg),
                alignment: Alignment.centerLeft,
                decoration: BoxDecoration(
                  color: context.panelHigh,
                  borderRadius: ClaroRadius.sm,
                  border: Border.all(
                    color: focused ? context.brandMint : context.border,
                  ),
                ),
                child: TextField(
                  controller: _controller,
                  focusNode: _focus,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(_maxDigits),
                  ],
                  style: ClaroType.subtitle.copyWith(color: context.textPrimary),
                  cursorColor: context.brandMint,
                  decoration: InputDecoration.collapsed(
                    hintText: 'e.g. 861234050123456',
                    hintStyle: ClaroType.subtitle.copyWith(color: context.textSecondary),
                  ),
                  onChanged: (_) => setState(() {}),
                  onSubmitted: (_) => _submit(),
                ),
              ),
              const SizedBox(height: ClaroSpacing.xl),
              ClaroPrimaryButton(text: 'Continue', onPressed: _submit, enabled: _valid),
            ],
          ),
        ),
      ),
    );
  }
}
