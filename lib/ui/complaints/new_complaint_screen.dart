import 'package:flutter/material.dart';

import '../../app/theme/claro_colors.dart';
import '../../app/theme/claro_dimens.dart';
import '../../app/theme/claro_type.dart';
import '../../core/api/api_exception.dart';
import '../../core/api/claro_pulse_api.dart';
import '../../core/api/models/device_models.dart';
import '../../core/api/models/pump_models.dart';
import '../common/ui_kit.dart';
import '../components/claro_primary_button.dart';
import '../home/home_dashboard.dart' show deviceTitle;

/// Raise a complaint: pick the problem, describe it, submit. Kept to one short
/// screen: a farmer with a broken pump should not fill in a long form.
class NewComplaintScreen extends StatefulWidget {
  const NewComplaintScreen({
    super.key,
    required this.device,
    required this.api,
    required this.onSubmitted,
    required this.onBack,
  });

  final MyDevice device;
  final ClaroPulseApi api;
  final VoidCallback onSubmitted;
  final VoidCallback onBack;

  @override
  State<NewComplaintScreen> createState() => _NewComplaintScreenState();
}

class _NewComplaintScreenState extends State<NewComplaintScreen> {
  ComplaintCategory? _category;
  final _description = TextEditingController();
  bool _submitting = false;
  String? _error;
  Complaint? _created;

  @override
  void dispose() {
    _description.dispose();
    super.dispose();
  }

  bool get _canSubmit => _category != null && _description.text.trim().length >= 5;

  Future<void> _submit() async {
    final category = _category;
    if (category == null || _submitting) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final created = await widget.api.createComplaint(
        deviceId: widget.device.deviceId,
        category: category,
        description: _description.text,
      );
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _created = created;
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
    final created = _created;
    return Scaffold(
      backgroundColor: ClaroColors.ink,
      body: SafeArea(
        child: created != null ? _Success(complaint: created, onDone: widget.onSubmitted) : _form(),
      ),
    );
  }

  Widget _form() {
    return Column(
      children: [
        BackHeader(title: 'Raise a complaint', onBack: widget.onBack),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(ClaroSpacing.xl, ClaroSpacing.sm, ClaroSpacing.xl, ClaroSpacing.xxl),
            children: [
              Panel(
                padding: const EdgeInsets.all(ClaroSpacing.md),
                child: Row(
                  children: [
                    const Icon(Icons.water_drop_outlined, color: ClaroColors.mint, size: 20),
                    const SizedBox(width: ClaroSpacing.sm),
                    Expanded(
                      child: Text(
                        '${deviceTitle(widget.device)} · ${widget.device.deviceUid}',
                        style: ClaroType.body.copyWith(color: ClaroColors.onInk),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: ClaroSpacing.xl),
              Text("What's the problem?", style: ClaroType.subtitle.copyWith(color: ClaroColors.onInk)),
              const SizedBox(height: ClaroSpacing.md),
              Wrap(
                spacing: ClaroSpacing.sm,
                runSpacing: ClaroSpacing.sm,
                children: [
                  for (final category in ComplaintCategory.values)
                    _CategoryChip(
                      label: category.label,
                      selected: _category == category,
                      onTap: () => setState(() => _category = category),
                    ),
                ],
              ),
              const SizedBox(height: ClaroSpacing.xl),
              Text('Tell us more', style: ClaroType.subtitle.copyWith(color: ClaroColors.onInk)),
              const SizedBox(height: ClaroSpacing.md),
              Container(
                padding: const EdgeInsets.all(ClaroSpacing.md),
                decoration: BoxDecoration(
                  color: ClaroColors.inkPanelHigh,
                  borderRadius: ClaroRadius.md,
                  border: Border.all(color: ClaroColors.borderDark),
                ),
                child: TextField(
                  controller: _description,
                  minLines: 4,
                  maxLines: 6,
                  maxLength: 500,
                  style: ClaroType.body.copyWith(color: ClaroColors.onInk),
                  cursorColor: ClaroColors.mint,
                  decoration: InputDecoration.collapsed(
                    hintText: 'For example: the pump starts but no water comes out.',
                    hintStyle: ClaroType.body.copyWith(color: ClaroColors.onInkMuted),
                  ),
                  onChanged: (_) => setState(() => _error = null),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: ClaroSpacing.sm),
                Text(_error!, style: ClaroType.caption.copyWith(color: ClaroColors.fault)),
              ],
              const SizedBox(height: ClaroSpacing.xl),
              ClaroPrimaryButton(
                text: 'Submit complaint',
                onPressed: _submit,
                enabled: _canSubmit,
                loading: _submitting,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: ClaroMotion.fast,
        padding: const EdgeInsets.symmetric(horizontal: ClaroSpacing.md, vertical: ClaroSpacing.sm),
        decoration: BoxDecoration(
          color: selected ? ClaroColors.mint : ClaroColors.inkPanel,
          borderRadius: ClaroRadius.pill,
          border: Border.all(color: selected ? ClaroColors.mint : ClaroColors.borderDark),
        ),
        child: Text(
          label,
          style: ClaroType.label.copyWith(color: selected ? ClaroColors.ink : ClaroColors.onInk),
        ),
      ),
    );
  }
}

class _Success extends StatelessWidget {
  const _Success({required this.complaint, required this.onDone});

  final Complaint complaint;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(ClaroSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(shape: BoxShape.circle, color: ClaroColors.mint.withValues(alpha: 0.14)),
              child: const Icon(Icons.check_rounded, color: ClaroColors.mint, size: 40),
            ),
            const SizedBox(height: ClaroSpacing.lg),
            Text('Complaint raised', style: ClaroType.title.copyWith(color: ClaroColors.onInk)),
            const SizedBox(height: ClaroSpacing.xs),
            Text(
              'Ticket ${complaint.ticketNo}',
              style: ClaroType.readout.copyWith(color: ClaroColors.mint),
            ),
            const SizedBox(height: ClaroSpacing.sm),
            Text(
              "Our service team will look into it. You'll see updates in Complaints and in your alerts.",
              textAlign: TextAlign.center,
              style: ClaroType.body.copyWith(color: ClaroColors.onInkMuted),
            ),
            const SizedBox(height: ClaroSpacing.xl),
            ClaroPrimaryButton(text: 'Done', onPressed: onDone),
          ],
        ),
      ),
    );
  }
}
