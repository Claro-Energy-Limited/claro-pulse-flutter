import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme/claro_colors.dart';
import '../../app/theme/claro_dimens.dart';
import '../../app/theme/claro_type.dart';
import '../../core/api/api_exception.dart';
import '../components/claro_otp_row.dart';
import '../components/claro_powered_by.dart';
import '../components/claro_primary_button.dart';

const _resendCooldownSeconds = 30;
const _phoneLength = 10;

enum _AuthStep { phone, otp, signedIn }

/// Phone number + OTP sign-in, ported from the Kotlin `AuthScreen`.
///
/// Layout: a brand band on top over a photo that fades into the dark
/// background, and the form in a sheet rising from the bottom edge, where a
/// thumb rests. When the keyboard opens, the brand band gives up the space;
/// the form itself never moves.
///
/// [onSendOtp] and [onVerifyOtp] do the real work and throw [ApiException] on
/// failure; the screen only shows progress and the error message.
class AuthScreen extends StatefulWidget {
  const AuthScreen({
    super.key,
    required this.onSendOtp,
    required this.onVerifyOtp,
    required this.onAuthenticated,
    this.otpHint,
  });

  final Future<void> Function(String phone) onSendOtp;
  final Future<void> Function(String phone, String code) onVerifyOtp;
  final VoidCallback onAuthenticated;

  /// Shown under the code boxes in mock mode, e.g. "Mock mode: use code 123456".
  final String? otpHint;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  _AuthStep _step = _AuthStep.phone;
  bool _forward = true;
  final _phoneController = TextEditingController();
  String _otp = '';
  bool _loading = false;
  String? _error;
  int _cooldown = 0;
  Timer? _cooldownTimer;
  Timer? _handoffTimer;

  String get _phone => _phoneController.text;

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _handoffTimer?.cancel();
    _phoneController.dispose();
    super.dispose();
  }

  void _goTo(_AuthStep step) {
    if (step == _step) return;
    setState(() {
      _forward = step.index > _step.index;
      _step = step;
    });
  }

  void _startCooldown() {
    _cooldownTimer?.cancel();
    setState(() => _cooldown = _resendCooldownSeconds);
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() => _cooldown--);
      if (_cooldown <= 0) timer.cancel();
    });
  }

  String _messageFor(Object error, String fallback) =>
      error is ApiException ? error.message : fallback;

  Future<void> _sendOtp() async {
    if (_phone.length != _phoneLength || _loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await widget.onSendOtp(_phone);
      if (!mounted) return;
      setState(() {
        _loading = false;
        _otp = '';
      });
      _goTo(_AuthStep.otp);
      _startCooldown();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = _messageFor(e, "Couldn't send the code. Check your connection and try again.");
      });
    }
  }

  Future<void> _verifyOtp() async {
    if (_otp.length != otpLength || _loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await widget.onVerifyOtp(_phone, _otp);
      if (!mounted) return;
      setState(() => _loading = false);
      _goTo(_AuthStep.signedIn);
      FocusManager.instance.primaryFocus?.unfocus();
      // The checkmark gets a beat on screen before handing off: an instant
      // cut reads as a glitch, not a confirmation.
      _handoffTimer = Timer(const Duration(milliseconds: 900), widget.onAuthenticated);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = _messageFor(e, "That code didn't match. Check it and try again.");
      });
    }
  }

  void _changeNumber() {
    _cooldownTimer?.cancel();
    setState(() {
      _otp = '';
      _error = null;
      _cooldown = 0;
    });
    _goTo(_AuthStep.phone);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ClaroColors.ink,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final height = constraints.maxHeight;
          return Stack(
            children: [
              // Background photo, fading into the ink background.
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: height * 0.6,
                child: Image.asset('assets/images/auth_background.jpg', fit: BoxFit.cover),
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: height * 0.6,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        ClaroColors.ink.withValues(alpha: 0.4),
                        ClaroColors.ink.withValues(alpha: 0.8),
                        ClaroColors.ink,
                      ],
                      stops: const [0, 0.7, 1],
                    ),
                  ),
                ),
              ),
              Column(
                children: [
                  const Expanded(child: _BrandBand()),
                  // Capped so a tall step can't push the brand band off screen;
                  // past the cap the sheet scrolls inside.
                  ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: height * 0.86),
                    child: _sheet(),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _sheet() {
    return DecoratedBox(
      // A thin gradient rim, mint fading to grey, around the top of the sheet.
      decoration: const BoxDecoration(
        borderRadius: ClaroRadius.sheet,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0x8078FC90), Color(0x1A78FC90), Color(0x33FFFFFF)],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(1, 1, 1, 0),
        child: ClipRRect(
          borderRadius: ClaroRadius.sheet,
          child: ColoredBox(
            color: ClaroColors.inkPanel,
            child: SafeArea(
              top: false,
              child: AnimatedSize(
                duration: ClaroMotion.base,
                alignment: Alignment.topCenter,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(ClaroSpacing.xl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_step != _AuthStep.signedIn) ...[
                        _StepDots(activeIndex: _step == _AuthStep.phone ? 0 : 1),
                        const SizedBox(height: ClaroSpacing.lg),
                      ],
                      AnimatedSwitcher(
                        duration: ClaroMotion.base,
                        layoutBuilder: (current, previous) => Stack(
                          alignment: Alignment.topCenter,
                          children: [...previous, if (current != null) current],
                        ),
                        transitionBuilder: _transition,
                        child: KeyedSubtree(key: ValueKey(_step), child: _stepContent()),
                      ),
                      const SizedBox(height: ClaroSpacing.xl),
                      const ClaroPoweredBy(captionColor: ClaroColors.onInkMuted),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Moving forward, the new step rises in from below; going back, it drops in from above.
  Widget _transition(Widget child, Animation<double> animation) {
    final incoming = child.key == ValueKey(_step);
    final direction = _forward ? 1.0 : -1.0;
    final offset = Tween<Offset>(
      begin: Offset(0, (incoming ? 0.25 : -0.25) * direction),
      end: Offset.zero,
    ).animate(animation);
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(position: offset, child: child),
    );
  }

  Widget _stepContent() {
    switch (_step) {
      case _AuthStep.phone:
        return _PhoneStep(
          controller: _phoneController,
          onChanged: (_) => setState(() => _error = null),
          onSubmit: _sendOtp,
          loading: _loading,
          error: _error,
        );
      case _AuthStep.otp:
        return _OtpStep(
          phone: _phone,
          otp: _otp,
          onOtpChanged: (v) => setState(() {
            _otp = v;
            _error = null;
          }),
          onVerify: _verifyOtp,
          onResend: _sendOtp,
          onChangeNumber: _changeNumber,
          loading: _loading,
          error: _error,
          cooldownSeconds: _cooldown,
          hint: widget.otpHint,
        );
      case _AuthStep.signedIn:
        return _SignedInStep(phone: _phone);
    }
  }
}

/// The brand half: typographic only. The photo behind it fades into the dark
/// background, so band and sheet read as one surface.
class _BrandBand extends StatelessWidget {
  const _BrandBand();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: ClaroSpacing.xl),
        child: Center(
          child: SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Claro Pulse',
                  style: ClaroType.displayLg.copyWith(letterSpacing: 0.5, color: ClaroColors.onInk),
                ),
                const SizedBox(height: ClaroSpacing.xs),
                Text(
                  'Your system, at a glance.',
                  style: ClaroType.body.copyWith(color: ClaroColors.mint.withValues(alpha: 0.8)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Two steps, phone then code: a progress cue so "Enter the code" doesn't read
/// as a dead end.
class _StepDots extends StatelessWidget {
  const _StepDots({required this.activeIndex});

  final int activeIndex;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < 2; i++) ...[
          if (i > 0) const SizedBox(width: ClaroSpacing.xs),
          AnimatedContainer(
            duration: ClaroMotion.base,
            height: 4,
            width: i == activeIndex ? 24 : 12,
            decoration: BoxDecoration(
              borderRadius: ClaroRadius.pill,
              color: i <= activeIndex ? ClaroColors.mint : ClaroColors.borderDark,
            ),
          ),
        ],
      ],
    );
  }
}

class _PhoneStep extends StatelessWidget {
  const _PhoneStep({
    required this.controller,
    required this.onChanged,
    required this.onSubmit,
    required this.loading,
    required this.error,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onSubmit;
  final bool loading;
  final String? error;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Sign in', style: ClaroType.displayLg.copyWith(color: ClaroColors.onInk)),
        const SizedBox(height: ClaroSpacing.sm),
        Text(
          "Enter your mobile number. We'll send a code to verify it's you.",
          style: ClaroType.body.copyWith(color: ClaroColors.onInkMuted),
        ),
        const SizedBox(height: ClaroSpacing.xl),
        _PhoneField(controller: controller, onChanged: onChanged, onSubmit: onSubmit),
        if (error != null) ...[
          const SizedBox(height: ClaroSpacing.sm),
          Text(error!, style: ClaroType.caption.copyWith(color: ClaroColors.fault)),
        ],
        const SizedBox(height: ClaroSpacing.xl),
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller,
          builder: (context, value, _) => ClaroPrimaryButton(
            text: 'Send code',
            onPressed: onSubmit,
            enabled: value.text.length == _phoneLength,
            loading: loading,
          ),
        ),
      ],
    );
  }
}

class _PhoneField extends StatefulWidget {
  const _PhoneField({required this.controller, required this.onChanged, required this.onSubmit});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onSubmit;

  @override
  State<_PhoneField> createState() => _PhoneFieldState();
}

class _PhoneFieldState extends State<_PhoneField> {
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final focused = _focus.hasFocus;
    return AnimatedContainer(
      duration: ClaroMotion.fast,
      height: 56,
      decoration: BoxDecoration(
        // Lifted above the sheet: an equal-tone field on a dark panel is only
        // findable by its border.
        color: ClaroColors.inkPanelHigh,
        borderRadius: ClaroRadius.sm,
        border: Border.all(
          color: focused ? ClaroColors.mint.withValues(alpha: 0.8) : ClaroColors.borderDark,
        ),
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: ClaroSpacing.lg, right: ClaroSpacing.sm),
            child: Text('+91', style: ClaroType.subtitle.copyWith(color: ClaroColors.onInkMuted)),
          ),
          Container(width: 1, height: 24, color: ClaroColors.borderDark),
          const SizedBox(width: ClaroSpacing.sm),
          Expanded(
            child: TextField(
              controller: widget.controller,
              focusNode: _focus,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.telephoneNumberNational],
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(_phoneLength),
              ],
              style: ClaroType.subtitle.copyWith(color: ClaroColors.onInk),
              cursorColor: ClaroColors.mint,
              decoration: InputDecoration.collapsed(
                hintText: '98765 43210',
                hintStyle: ClaroType.subtitle.copyWith(color: ClaroColors.onInkMuted),
              ),
              onChanged: widget.onChanged,
              onSubmitted: (_) => widget.onSubmit(),
            ),
          ),
          const SizedBox(width: ClaroSpacing.lg),
        ],
      ),
    );
  }
}

class _OtpStep extends StatelessWidget {
  const _OtpStep({
    required this.phone,
    required this.otp,
    required this.onOtpChanged,
    required this.onVerify,
    required this.onResend,
    required this.onChangeNumber,
    required this.loading,
    required this.error,
    required this.cooldownSeconds,
    required this.hint,
  });

  final String phone;
  final String otp;
  final ValueChanged<String> onOtpChanged;
  final VoidCallback onVerify;
  final VoidCallback onResend;
  final VoidCallback onChangeNumber;
  final bool loading;
  final String? error;
  final int cooldownSeconds;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final canResend = cooldownSeconds == 0 && !loading;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Enter the code', style: ClaroType.displayLg.copyWith(color: ClaroColors.onInk)),
        const SizedBox(height: ClaroSpacing.sm),
        Text(
          'We sent a 6-digit code to +91 $phone',
          style: ClaroType.body.copyWith(color: ClaroColors.onInkMuted),
        ),
        const SizedBox(height: ClaroSpacing.xl),
        ClaroOtpRow(value: otp, onChanged: onOtpChanged),
        if (error != null) ...[
          const SizedBox(height: ClaroSpacing.sm),
          Text(error!, style: ClaroType.caption.copyWith(color: ClaroColors.fault)),
        ],
        if (hint != null) ...[
          const SizedBox(height: ClaroSpacing.sm),
          Text(hint!, style: ClaroType.caption.copyWith(color: ClaroColors.warn)),
        ],
        const SizedBox(height: ClaroSpacing.xl),
        ClaroPrimaryButton(
          text: 'Verify',
          onPressed: onVerify,
          enabled: otp.length == otpLength,
          loading: loading,
        ),
        const SizedBox(height: ClaroSpacing.lg),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _TextAction(
              text: 'Change number',
              color: ClaroColors.onInkMuted,
              onTap: loading ? null : onChangeNumber,
            ),
            _TextAction(
              text: cooldownSeconds > 0 ? 'Resend in ${cooldownSeconds}s' : 'Resend code',
              color: cooldownSeconds > 0 ? ClaroColors.onInkMuted : ClaroColors.mint,
              onTap: canResend ? onResend : null,
            ),
          ],
        ),
      ],
    );
  }
}

class _TextAction extends StatelessWidget {
  const _TextAction({required this.text, required this.color, required this.onTap});

  final String text;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(ClaroSpacing.sm),
        child: Text(text, style: ClaroType.label.copyWith(color: color)),
      ),
    );
  }
}

class _SignedInStep extends StatelessWidget {
  const _SignedInStep({required this.phone});

  final String phone;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: ClaroColors.mintDeep.withValues(alpha: 0.25),
          ),
          child: const Icon(Icons.check, color: ClaroColors.mint, size: 32),
        ),
        const SizedBox(height: ClaroSpacing.lg),
        Text("You're signed in", style: ClaroType.title.copyWith(color: ClaroColors.onInk)),
        const SizedBox(height: ClaroSpacing.xs),
        Text('+91 $phone', style: ClaroType.body.copyWith(color: ClaroColors.onInkMuted)),
      ],
    );
  }
}
