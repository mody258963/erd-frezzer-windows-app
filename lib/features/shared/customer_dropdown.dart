import 'package:flutter/material.dart';

import '../../core/l10n/api_labels.dart';
import '../../data/models/customer_model.dart';
import '../../data/repositories/customer_repository.dart';
import '../../di/injection.dart';

/// Credit customers (Saturday settlement applies to credit accounts).
Future<List<CustomerModel>> loadCreditCustomers({int perPage = 200}) async {
  final all = await getIt<CustomerRepository>().list(
    type: 'credit',
    perPage: perPage,
  );
  return all.where((c) => c.isActive).toList()
    ..sort((a, b) => b.outstandingBalance.compareTo(a.outstandingBalance));
}

String customerDisplayLabel(BuildContext context, CustomerModel c) {
  final balance = formatMoney(context, c.outstandingBalance);
  return '${c.name} ($balance)';
}

/// Dropdown that shows customer names; submits customer id to the API.
class CustomerDropdown extends StatelessWidget {
  const CustomerDropdown({
    required this.customers,
    required this.value,
    required this.onChanged,
    required this.label,
    this.validator,
    super.key,
  });

  final List<CustomerModel> customers;
  final String? value;
  final ValueChanged<String?> onChanged;
  final String label;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    final selected =
        value != null && customers.any((c) => c.id == value) ? value : null;

    return DropdownButtonFormField<String>(
      value: selected,
      decoration: InputDecoration(labelText: label),
      isExpanded: true,
      items: [
        for (final c in customers)
          DropdownMenuItem(
            value: c.id,
            child: Text(
              customerDisplayLabel(context, c),
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
      onChanged: customers.isEmpty ? null : onChanged,
      validator: validator,
    );
  }
}
