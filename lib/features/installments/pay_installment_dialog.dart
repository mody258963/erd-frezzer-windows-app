import 'package:flutter/material.dart';

import '../../core/l10n/api_labels.dart';
import '../../core/l10n/l10n_extension.dart';
import '../../data/models/supplier_installment_model.dart';
import '../shared/form_field_spacing.dart';

/// Result of the pay-installment dialog.
class PayInstallmentResult {
  const PayInstallmentResult({
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

class PayInstallmentDialog extends StatefulWidget {
  const PayInstallmentDialog({required this.installment, super.key});

  final SupplierInstallmentModel installment;

  static Future<PayInstallmentResult?> show(
    BuildContext context,
    SupplierInstallmentModel installment,
  ) {
    return showDialog<PayInstallmentResult>(
      context: context,
      builder: (ctx) => PayInstallmentDialog(installment: installment),
    );
  }

  @override
  State<PayInstallmentDialog> createState() => _PayInstallmentDialogState();
}

class _PayInstallmentDialogState extends State<PayInstallmentDialog> {
  late final TextEditingController _amountCtrl;
  late final TextEditingController _notesCtrl;
  late String _paymentMethod;
  bool _payFullBalance = false;

  SupplierInstallmentModel get inst => widget.installment;

  @override
  void initState() {
    super.initState();
    final due = inst.remainingBalance;
    _amountCtrl = TextEditingController(
      text: due > 0 ? due.toStringAsFixed(2) : '',
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

  void _applyPayFullBalance() {
    setState(() {
      _payFullBalance = true;
      _amountCtrl.text = inst.remainingBalance.toStringAsFixed(2);
    });
  }

  PayInstallmentResult? _validateAndBuild() {
    final l10n = context.l10n;
    final balanceDue = inst.remainingBalance;

    if (!inst.canPay) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.installmentAlreadyPaid)),
      );
      return null;
    }

    if (_payFullBalance) {
      return PayInstallmentResult(
        paymentMethod: _paymentMethod,
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        payFullBalance: true,
      );
    }

    final amount = double.tryParse(_amountCtrl.text.trim().replaceAll(',', ''));
    if (amount == null || amount <= 0 || amount > balanceDue) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.installmentPayAmountInvalid(
            balanceDue.toStringAsFixed(2),
          )),
        ),
      );
      return null;
    }

    return PayInstallmentResult(
      paymentMethod: _paymentMethod,
      amount: amount,
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final balanceDue = inst.remainingBalance;
    final dueLabel = inst.dueDate != null && inst.dueDate!.length >= 10
        ? inst.dueDate!.substring(0, 10)
        : (inst.dueDate ?? '—');

    return AlertDialog(
      title: Text(
        inst.installmentNo > 0
            ? l10n.payInstallmentTitle(inst.installmentNo)
            : l10n.payInstallmentTitleGeneric,
      ),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (inst.supplierName != null && inst.supplierName!.isNotEmpty)
                Text(
                  inst.supplierName!,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              Text(
                l10n.dueDate(dueLabel),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 16),
              _SummaryRow(
                label: l10n.installmentScheduled,
                value: formatMoney(context, inst.amount),
              ),
              _SummaryRow(
                label: l10n.installmentAlreadyPaidAmount,
                value: formatMoney(context, inst.amountPaid),
              ),
              _SummaryRow(
                label: l10n.installmentBalanceDue,
                value: formatMoney(context, balanceDue),
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
                    onPressed: balanceDue > 0 ? _applyPayFullBalance : null,
                    child: Text(l10n.payFullBalance(formatMoney(context, balanceDue))),
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
          child: Text(l10n.pay),
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
