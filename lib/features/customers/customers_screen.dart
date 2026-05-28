import 'package:flutter/material.dart';

import '../../core/l10n/api_labels.dart';
import '../../core/l10n/l10n_extension.dart';
import '../../data/models/customer_model.dart';
import '../../data/repositories/customer_repository.dart';
import '../../di/injection.dart';
import '../shared/entity_list_tile.dart';
import '../shared/form_field_spacing.dart';
import '../shared/loading_error.dart';
import '../shared/page_header.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  final _search = TextEditingController();
  List<CustomerModel>? _items;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await getIt<CustomerRepository>().list(search: _search.text);
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHeader(
          title: l10n.customersTitle,
          searchField: TextField(
            controller: _search,
            decoration: InputDecoration(
              labelText: l10n.search,
              prefixIcon: const Icon(Icons.search),
            ),
            onSubmitted: (_) => _load(),
          ),
          actions: [
            IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
            FilledButton.icon(
              onPressed: () => _showForm(context),
              icon: const Icon(Icons.add),
              label: Text(l10n.newCustomer),
            ),
          ],
        ),
        Expanded(
          child: _loading
              ? const LoadingView()
              : _error != null
                  ? ErrorView(message: _error!, onRetry: _load)
                  : EntityListView(
                      itemCount: _items!.length,
                      emptyMessage: l10n.noData,
                      itemBuilder: (context, i) {
                        final c = _items![i];
                        return EntityListTile(
                          title: c.name,
                          subtitle: l10n.customerRowSubtitle(
                            localizeCustomerType(context, c.type),
                            '${l10n.balance}: ${formatMoney(context, c.outstandingBalance)}',
                          ),
                          leading: CircleAvatar(
                            child: Text(
                              c.name.isNotEmpty ? c.name[0].toUpperCase() : '?',
                            ),
                          ),
                          onTap: () => _showDetail(context, c),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Future<void> _showDetail(BuildContext context, CustomerModel c) async {
    final l10n = context.l10n;
    final balance = await getIt<CustomerRepository>().balance(c.id);
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(c.name),
        content: Text(
          l10n.balanceValue('${balance['outstanding_balance'] ?? balance}'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.close),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _showForm(context, customer: c);
            },
            child: Text(l10n.edit),
          ),
        ],
      ),
    );
  }

  Future<void> _showForm(BuildContext context, {CustomerModel? customer}) async {
    final l10n = context.l10n;
    final name = TextEditingController(text: customer?.name ?? '');
    final type = ValueNotifier(customer?.type ?? 'cash');
    final phone = TextEditingController(text: customer?.phone ?? '');
    final address = TextEditingController(text: customer?.address ?? '');
    final creditLimit = TextEditingController(text: '${customer?.creditLimit ?? 0}');

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(customer == null ? l10n.newCustomer : l10n.editCustomer),
        content: SizedBox(
          width: 400,
          child: ValueListenableBuilder(
            valueListenable: type,
            builder: (ctx, t, _) => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: spacedFormFields([
                TextField(
                  controller: name,
                  decoration: InputDecoration(labelText: l10n.name),
                ),
                DropdownButtonFormField<String>(
                  value: t,
                  decoration: InputDecoration(labelText: l10n.customerType),
                  items: [
                    DropdownMenuItem(value: 'cash', child: Text(l10n.cash)),
                    DropdownMenuItem(value: 'credit', child: Text(l10n.credit)),
                  ],
                  onChanged: (v) => type.value = v ?? 'cash',
                ),
                TextField(
                  controller: phone,
                  decoration: InputDecoration(labelText: l10n.phoneNumber),
                ),
                TextField(
                  controller: address,
                  decoration: InputDecoration(labelText: l10n.supplierAddress),
                ),
                if (t == 'credit')
                  TextField(
                    controller: creditLimit,
                    decoration: InputDecoration(labelText: l10n.creditLimit),
                    keyboardType: TextInputType.number,
                  ),
              ]),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.save),
          ),
        ],
      ),
    );
    if (ok != true) return;

    final body = {
      'name': name.text,
      'type': type.value,
      'phone': phone.text,
      'address': address.text,
      if (type.value == 'credit')
        'credit_limit': double.tryParse(creditLimit.text) ?? 0,
    };
    final repo = getIt<CustomerRepository>();
    if (customer != null) {
      await repo.update(customer.id, body);
    } else {
      await repo.create(body);
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.customerSaved)),
      );
    }
    await _load();
  }
}
