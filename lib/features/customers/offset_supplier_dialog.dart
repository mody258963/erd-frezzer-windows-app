import 'package:flutter/material.dart';

import '../../core/l10n/api_labels.dart';
import '../../core/l10n/l10n_extension.dart';
import '../../data/models/linked_balance_model.dart';
import '../shared/form_field_spacing.dart';

class OffsetSupplierResult {
  const OffsetSupplierResult({
    this.amount,
    this.notes,
    this.offsetFull = false,
  });

  final double? amount;
  final String? notes;
  final bool offsetFull;
}

class OffsetSupplierDialog extends StatefulWidget {
  const OffsetSupplierDialog({required this.linkedBalance, super.key});

  final LinkedBalanceModel linkedBalance;

  static Future<OffsetSupplierResult?> show(
    BuildContext context,
    LinkedBalanceModel linkedBalance,
  ) {
    return showDialog<OffsetSupplierResult>(
      context: context,
      builder: (ctx) => OffsetSupplierDialog(linkedBalance: linkedBalance),
    );
  }

  @override
  State<OffsetSupplierDialog> createState() => _OffsetSupplierDialogState();
}

class _OffsetSupplierDialogState extends State<OffsetSupplierDialog> {
  late final TextEditingController _amountCtrl;
  late final TextEditingController _notesCtrl;
  bool _offsetFull = false;

  LinkedBalanceModel get lb => widget.linkedBalance;

  @override
  void initState() {
    super.initState();
    final max = lb.maxOffsetAmount;
    _amountCtrl = TextEditingController(
      text: max > 0 ? max.toStringAsFixed(2) : '',
    );
    _notesCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  OffsetSupplierResult? _validateAndBuild() {
    final l10n = context.l10n;
    final max = lb.maxOffsetAmount;

    if (max <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.offsetNotAvailable)),
      );
      return null;
    }

    if (_offsetFull) {
      return OffsetSupplierResult(
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        offsetFull: true,
      );
    }

    final amount = double.tryParse(_amountCtrl.text.trim().replaceAll(',', ''));
    if (amount == null || amount <= 0 || amount > max) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.offsetAmountInvalid(max.toStringAsFixed(2))),
        ),
      );
      return null;
    }

    return OffsetSupplierResult(
      amount: amount,
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final max = lb.maxOffsetAmount;

    return AlertDialog(
      title: Text(l10n.offsetSupplierTitle),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SummaryRow(
                label: l10n.linkedCustomerReceivable,
                value: formatMoney(context, lb.customerBalance),
              ),
              _SummaryRow(
                label: l10n.linkedSupplierPayable,
                value: formatMoney(context, lb.supplierDebt),
              ),
              _SummaryRow(
                label: l10n.linkedNetBalance,
                value: formatNetDirection(context, lb),
                highlight: true,
              ),
              const SizedBox(height: 16),
              ...spacedFormFields([
                TextField(
                  controller: _amountCtrl,
                  enabled: !_offsetFull,
                  decoration: InputDecoration(
                    labelText: l10n.offsetAmountLabel,
                    suffixText: 'EGP',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  onChanged: (_) {
                    if (_offsetFull) setState(() => _offsetFull = false);
                  },
                ),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextButton(
                    onPressed: max > 0
                        ? () {
                            setState(() {
                              _offsetFull = true;
                              _amountCtrl.text = max.toStringAsFixed(2);
                            });
                          }
                        : null,
                    child: Text(l10n.offsetFullAmount(formatMoney(context, max))),
                  ),
                ),
                TextField(
                  controller: _notesCtrl,
                  decoration: InputDecoration(labelText: l10n.notesOptional),
                  maxLines: 2,
                ),
              ]),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () {
            final result = _validateAndBuild();
            if (result != null) Navigator.pop(context, result);
          },
          child: Text(l10n.offsetConfirm),
        ),
      ],
    );
  }
}

String formatNetDirection(BuildContext context, LinkedBalanceModel lb) {
  final l10n = context.l10n;
  final amount = formatMoney(context, lb.netAmount);
  return switch (lb.netDirection) {
    'they_owe_us' => l10n.netTheyOweUs(amount),
    'we_owe_them' => l10n.netWeOweThem(amount),
    _ => l10n.netBalanced,
  };
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: highlight ? FontWeight.w800 : FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}
