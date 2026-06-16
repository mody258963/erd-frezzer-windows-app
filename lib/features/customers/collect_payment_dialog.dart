import 'package:flutter/material.dart';

import '../../core/l10n/api_labels.dart';
import '../../core/l10n/l10n_extension.dart';
import '../shared/form_field_spacing.dart';

class CollectPaymentResult {
  const CollectPaymentResult({
    required this.paymentMethod,
    this.amount,
    this.notes,
    this.payFullBalance = false,
  });

  final String paymentMethod;
  final double? amount;
  final String? notes;
  final bool payFullBalance;
}

class CollectPaymentDialog extends StatefulWidget {
  const CollectPaymentDialog({
    required this.customerName,
    required this.outstandingBalance,
    super.key,
  });

  final String customerName;
  final double outstandingBalance;

  static Future<CollectPaymentResult?> show(
    BuildContext context, {
    required String customerName,
    required double outstandingBalance,
  }) {
    return showDialog<CollectPaymentResult>(
      context: context,
      builder: (ctx) => CollectPaymentDialog(
        customerName: customerName,
        outstandingBalance: outstandingBalance,
      ),
    );
  }

  @override
  State<CollectPaymentDialog> createState() => _CollectPaymentDialogState();
}

class _CollectPaymentDialogState extends State<CollectPaymentDialog> {
  late final TextEditingController _amountCtrl;
  late final TextEditingController _notesCtrl;
  late String _paymentMethod;
  bool _payFullBalance = false;

  @override
  void initState() {
    super.initState();
    final bal = widget.outstandingBalance;
    _amountCtrl = TextEditingController(
      text: bal > 0 ? bal.toStringAsFixed(2) : '',
    );
    _notesCtrl = TextEditingController();
    _paymentMethod = 'cash';
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  CollectPaymentResult? _validateAndBuild() {
    final l10n = context.l10n;
    final balance = widget.outstandingBalance;

    if (balance <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.customerNoBalanceDue)),
      );
      return null;
    }

    if (_payFullBalance) {
      return CollectPaymentResult(
        paymentMethod: _paymentMethod,
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        payFullBalance: true,
      );
    }

    final amount = double.tryParse(_amountCtrl.text.trim().replaceAll(',', ''));
    if (amount == null || amount <= 0 || amount > balance) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.customerPayAmountInvalid(balance.toStringAsFixed(2)),
          ),
        ),
      );
      return null;
    }

    return CollectPaymentResult(
      paymentMethod: _paymentMethod,
      amount: amount,
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final balance = widget.outstandingBalance;

    return AlertDialog(
      title: Text(l10n.collectPaymentTitle),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.customerName,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 16),
              _SummaryRow(
                label: l10n.balance,
                value: formatMoney(context, balance),
                highlight: true,
              ),
              const SizedBox(height: 16),
              ...spacedFormFields([
                TextField(
                  controller: _amountCtrl,
                  enabled: !_payFullBalance,
                  decoration: InputDecoration(
                    labelText: l10n.payAmountLabel,
                    suffixText: 'EGP',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  onChanged: (_) {
                    if (_payFullBalance) setState(() => _payFullBalance = false);
                  },
                ),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextButton(
                    onPressed: balance > 0
                        ? () {
                            setState(() {
                              _payFullBalance = true;
                              _amountCtrl.text = balance.toStringAsFixed(2);
                            });
                          }
                        : null,
                    child: Text(l10n.payFullBalance(formatMoney(context, balance))),
                  ),
                ),
                DropdownButtonFormField<String>(
                  initialValue: _paymentMethod,
                  decoration: InputDecoration(labelText: l10n.paymentMethod),
                  isExpanded: true,
                  items: [
                    DropdownMenuItem(value: 'cash', child: Text(l10n.cash)),
                    DropdownMenuItem(
                      value: 'bank_transfer',
                      child: Text(l10n.bankTransfer),
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
                  controller: _notesCtrl,
                  decoration: InputDecoration(labelText: l10n.notesOptional),
                  maxLines: 2,
                  maxLength: 2000,
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
          child: Text(l10n.collectPaymentConfirm),
        ),
      ],
    );
  }
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
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
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
