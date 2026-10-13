import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme/claro_colors.dart';
import '../../app/theme/claro_dimens.dart';
import '../../app/theme/claro_type.dart';

const int otpLength = 6;

/// Six OTP digit boxes, ported from the Kotlin `ClaroPulseOtpRow`.
///
/// One invisible real text field sits over the six boxes and handles focus, the
/// keyboard, paste and SMS autofill; the boxes are only a painted view of its
/// value. Six separate fields would need manual focus-jumping, backspace and
/// paste handling per box. Digits render in JetBrains Mono, like every number.
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final value = widget.value;
    return SizedBox(
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
          // The real field: invisible, covering the whole row, so a tap anywhere focuses it.
          Positioned.fill(
            child: Opacity(
              opacity: 0,
              child: TextField(
                controller: _controller,
                focusNode: widget.focusNode,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.oneTimeCode],
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(otpLength),
                ],
                showCursor: false,
                enableInteractiveSelection: false,
                decoration: const InputDecoration(border: InputBorder.none, counterText: ''),
                onChanged: widget.onChanged,
              ),
            ),
          ),
        ],
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
