import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_cubit.dart';
import '../../core/branch/branch_filter_cubit.dart';
import '../../core/branch/branch_filter_scope.dart';
import '../../core/catalog/catalog_refresh_scheduler.dart';
import '../../core/connectivity/connectivity_cubit.dart';
import '../../core/events/app_refresh_bus.dart';
import '../../core/l10n/api_labels.dart';
import '../../core/l10n/l10n_extension.dart';
import '../../data/models/customer_model.dart';
import '../../data/repositories/customer_repository.dart';
import '../../di/injection.dart';
import '../shared/entity_list_tile.dart';
import '../shared/form_field_spacing.dart';
import '../shared/loading_error.dart';
import '../shared/page_header.dart';
import '../shared/settlement_cycle_dropdown.dart';

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
    getIt<AppRefreshBus>().addListener(_onAppRefresh);
    _load();
  }

  @override
  void dispose() {
    getIt<AppRefreshBus>().removeListener(_onAppRefresh);
    _search.dispose();
    super.dispose();
  }

  void _onAppRefresh(AppRefreshKind kind) {
    if (!mounted) return;
    if (kind == AppRefreshKind.branchFilter) _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await getIt<CustomerRepository>().list(
        search: _search.text,
        branchId: apiBranchIdFromContext(context),
      );
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
                          onTap: () => context.push('/customers/${c.id}'),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Future<void> _showForm(BuildContext context, {CustomerModel? customer}) async {
    final l10n = context.l10n;
    final isCreate = customer == null;
    String? branchLabel;
    if (isCreate) {
      final branchId = requiredBranchIdFromContext(context);
      if (branchId == null || branchId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.customerBranchRequired)),
        );
        return;
      }
      final user = context.read<AuthCubit>().state.user;
      branchLabel = context.read<BranchFilterCubit>().state.branchNameFor(branchId) ??
          user?.branchName ??
          branchId;
    }

    final name = TextEditingController(text: customer?.name ?? '');
    final type = ValueNotifier(customer?.type ?? 'cash');
    final settlementCycle =
        ValueNotifier(customer?.settlementCycle ?? 'weekly');
    final phone = TextEditingController(text: customer?.phone ?? '');
    final address = TextEditingController(text: customer?.address ?? '');
    final creditLimit =
        TextEditingController(text: '${customer?.creditLimit ?? 0}');

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isCreate ? l10n.newCustomer : l10n.editCustomer),
        content: SizedBox(
          width: 400,
          child: ValueListenableBuilder(
            valueListenable: type,
            builder: (ctx, t, _) => ValueListenableBuilder(
              valueListenable: settlementCycle,
              builder: (ctx, cycle, _) => Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: spacedFormFields([
                  if (branchLabel != null && branchLabel.isNotEmpty)
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Chip(label: Text(branchLabel)),
                    ),
                  TextField(
                    controller: name,
                    decoration: InputDecoration(labelText: l10n.name),
                  ),
                  DropdownButtonFormField<String>(
                    initialValue: t,
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
                  if (t == 'credit') ...[
                    TextField(
                      controller: creditLimit,
                      decoration: InputDecoration(labelText: l10n.creditLimit),
                      keyboardType: TextInputType.number,
                    ),
                    SettlementCycleDropdown(
                      value: cycle,
                      onChanged: (v) => settlementCycle.value = v,
                    ),
                  ],
                ]),
              ),
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
      if (type.value == 'credit') ...{
        'credit_limit': double.tryParse(creditLimit.text) ?? 0,
        'settlement_cycle': settlementCycle.value,
      },
    };
    final repo = getIt<CustomerRepository>();
    if (customer != null) {
      await repo.update(customer.id, body);
    } else {
      await repo.create(
        body,
        branchId: requiredBranchIdFromContext(context),
      );
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.customerSaved)),
      );
    }
    await _load();
    if (getIt<ConnectivityCubit>().state.isOnline) {
      unawaited(getIt<CatalogRefreshScheduler>().refreshNow());
    }
  }
}
