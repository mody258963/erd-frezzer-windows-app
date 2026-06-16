import 'package:flutter/material.dart';

import '../../core/l10n/api_labels.dart';
import '../../core/l10n/l10n_extension.dart';
import '../shared/form_field_spacing.dart';

class EditPaymentResult {
  const EditPaymentResult({
    required this.amount,
    required this.paymentMethod,
    this.notes,
  });

  final double amount;
  final String paymentMethod;
  final String? notes;
}

class EditPaymentDialog extends StatefulWidget {
  const EditPaymentDialog({
    required this.currentAmount,
    this.paymentMethod = 'cash',
    this.notes,
    super.key,
  });

  final double currentAmount;
  final String paymentMethod;
  final String? notes;

  static Future<EditPaymentResult?> show(
    BuildContext context, {
    required double currentAmount,
    String paymentMethod = 'cash',
    String? notes,
  }) {
    return showDialog<EditPaymentResult>(
      context: context,
      builder: (ctx) => EditPaymentDialog(
        currentAmount: currentAmount,
        paymentMethod: paymentMethod,
        notes: notes,
      ),
    );
  }

  @override
  State<EditPaymentDialog> createState() => _EditPaymentDialogState();
}

class _EditPaymentDialogState extends State<EditPaymentDialog> {
  late final TextEditingController _amount;
  late final TextEditingController _notes;
  late String _paymentMethod;

  @override
  void initState() {
    super.initState();
    _amount = TextEditingController(
      text: widget.currentAmount.toStringAsFixed(2),
    );
    _notes = TextEditingController(text: widget.notes ?? '');
    _paymentMethod = widget.paymentMethod;
  }

  @override
  void dispose() {
    _amount.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _save() {
    final l10n = context.l10n;
    final parsed = double.tryParse(_amount.text.trim().replaceAll(',', ''));
    if (parsed == null || parsed <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.invalidAmount)),
      );
      return;
    }
    Navigator.pop(
      context,
      EditPaymentResult(
        amount: parsed,
        paymentMethod: _paymentMethod,
        notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(l10n.editPayment),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: spacedFormFields([
              Text(
                l10n.editPaymentHint,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      height: 1.4,
                    ),
              ),
              TextField(
                controller: _amount,
                autofocus: true,
                decoration: InputDecoration(labelText: l10n.amount),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                onSubmitted: (_) => _save(),
              ),
              DropdownButtonFormField<String>(
                initialValue: _paymentMethod,
                decoration: InputDecoration(labelText: l10n.paymentMethod),
                isExpanded: true,
                items: [
                  DropdownMenuItem(
                    value: 'cash',
                    child: Text(localizePaymentType(context, 'cash')),
                  ),
                  DropdownMenuItem(
                    value: 'bank_transfer',
                    child: Text(localizePaymentType(context, 'bank_transfer')),
                  ),
                  DropdownMenuItem(
                    value: 'check',
                    child: Text(l10n.paymentCheck),
                  ),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _paymentMethod = v);
                },
              ),
              TextField(
                controller: _notes,
                decoration: InputDecoration(labelText: l10n.notes),
                maxLines: 2,
              ),
            ]),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: _save,
          child: Text(l10n.save),
        ),
      ],
    );
  }
}
