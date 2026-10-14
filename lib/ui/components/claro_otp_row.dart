import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme/claro_colors.dart';
import '../../app/theme/claro_dimens.dart';
import '../../app/theme/claro_type.dart';

const int otpLength = 6;

/// Six OTP digit boxes, ported from the Kotlin `ClaroPulseOtpRow`.
///
/// One real text field sits over the six boxes and handles focus, the keyboard,
/// paste and SMS autofill; the boxes are only a painted view of its value. Like
/// the Kotlin version, the field stays fully present with TRANSPARENT text and
/// cursor (not hidden), so it keeps receiving taps and keyboard input. Tapping
/// anywhere on the row focuses it and opens the keyboard.
class ClaroOtpRow extends StatefulWidget {
  const ClaroOtpRow({super.key, required this.value, required this.onChanged, this.focusNode});

  final String value;
  final ValueChanged<String> onChanged;
  final FocusNode? focusNode;

  @override
  State<ClaroOtpRow> createState() => _ClaroOtpRowState();
}

class _ClaroOtpRowState extends State<ClaroOtpRow> {
  late final TextEditingController _controller = TextEditingController(text: widget.value);
  FocusNode? _ownFocusNode;

  FocusNode get _focusNode => widget.focusNode ?? (_ownFocusNode ??= FocusNode());

  @override
  void didUpdateWidget(ClaroOtpRow old) {
    super.didUpdateWidget(old);
    if (widget.value != _controller.text) {
      _controller.value = TextEditingValue(
        text: widget.value,
        selection: TextSelection.collapsed(offset: widget.value.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _ownFocusNode?.dispose();
    super.dispose();
  }

  void _focus() {
    _focusNode.requestFocus();
    SystemChannels.textInput.invokeMethod<void>('TextInput.show');
  }

  @override
  Widget build(BuildContext context) {
    final value = widget.value;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _focus,
      child: SizedBox(
        height: 56,
        child: Stack(
          children: [
            Row(
              children: [
                for (var i = 0; i < otpLength; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  Expanded(child: _box(i, value)),
                ],
              ],
            ),
            // The real field: present and tappable, but its text and cursor are transparent.
            Positioned.fill(
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.oneTimeCode],
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(otpLength),
                ],
                style: const TextStyle(color: Colors.transparent, fontSize: 1),
                cursorColor: Colors.transparent,
                showCursor: false,
                enableInteractiveSelection: false,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  counterText: '',
                  filled: false,
                  isCollapsed: true,
                ),
                onChanged: widget.onChanged,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _box(int i, String value) {
    final filled = i < value.length;
    final isNext = i == value.length;
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        // Lifted off the panel behind, so empty boxes read as inputs, not outlines.
        color: ClaroColors.inkPanelHigh,
        borderRadius: ClaroRadius.sm,
        border: Border.all(
          width: filled || isNext ? 2 : 1,
          color: filled
              ? ClaroColors.onInk
              : isNext
                  ? ClaroColors.mint
                  : ClaroColors.borderDark,
        ),
      ),
      child: Text(
        filled ? value[i] : '',
        style: ClaroType.readoutLg.copyWith(color: ClaroColors.onInk),
      ),
    );
  }
}
