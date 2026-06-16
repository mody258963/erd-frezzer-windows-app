import 'package:flutter/material.dart';

import '../../../core/l10n/api_labels.dart';
import '../../../core/l10n/l10n_extension.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/linked_balance_model.dart';
import '../offset_supplier_dialog.dart';

class LinkedBalanceCard extends StatelessWidget {
  const LinkedBalanceCard({
    required this.linkedBalance,
    this.onOffset,
    this.onOpenCustomer,
    this.showSupplierLink = true,
    super.key,
  });

  final LinkedBalanceModel linkedBalance;
  final VoidCallback? onOffset;
  final VoidCallback? onOpenCustomer;
  final bool showSupplierLink;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final lb = linkedBalance;

    if (!lb.isLinked) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.link_off, color: Theme.of(context).colorScheme.outline),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l10n.linkedNotLinkedHint,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final netColor = switch (lb.netDirection) {
      'they_owe_us' => AppColors.success,
      'we_owe_them' => AppColors.warning,
      _ => Theme.of(context).colorScheme.primary,
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.link, color: netColor),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l10n.linkedBalanceTitle,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              ],
            ),
            if (showSupplierLink &&
                lb.supplierName != null &&
                lb.supplierName!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                l10n.linkedToSupplier(lb.supplierName!),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
            if (!showSupplierLink &&
                lb.customerName != null &&
                onOpenCustomer != null) ...[
              const SizedBox(height: 8),
              InkWell(
                onTap: onOpenCustomer,
                child: Text(
                  l10n.linkedToCustomer(lb.customerName!),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        decoration: TextDecoration.underline,
                      ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            _Line(
              label: l10n.linkedCustomerReceivable,
              value: formatMoney(context, lb.customerBalance),
            ),
            _Line(
              label: l10n.linkedSupplierPayable,
              value: formatMoney(context, lb.supplierDebt),
            ),
            const Divider(height: 20),
            _Line(
              label: l10n.linkedNetBalance,
              value: formatNetDirection(context, lb),
              bold: true,
              valueColor: netColor,
            ),
            if (onOffset != null && lb.maxOffsetAmount > 0) ...[
              const SizedBox(height: 12),
              FilledButton.tonalIcon(
                onPressed: onOffset,
                icon: const Icon(Icons.compare_arrows),
                label: Text(l10n.offsetSupplierAction),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({
    required this.label,
    required this.value,
    this.bold = false,
    this.valueColor,
  });

  final String label;
  final String value;
  final bool bold;
  final Color? valueColor;

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
                  fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
                  color: valueColor,
                ),
          ),
        ],
      ),
    );
  }
}
