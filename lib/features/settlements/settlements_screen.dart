import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/auth/auth_cubit.dart';
import '../../core/auth/role_permissions.dart';
import '../../core/l10n/api_labels.dart';
import '../../core/l10n/l10n_extension.dart';
import '../../data/models/customer_model.dart';
import '../../data/models/user_role.dart';
import '../../data/repositories/settlement_repository.dart';
import '../../di/injection.dart';
import '../shared/customer_dropdown.dart';
import '../shared/entity_list_tile.dart';
import '../shared/form_field_spacing.dart';
import '../shared/loading_error.dart';
import '../shared/page_header.dart';

class SettlementsScreen extends StatefulWidget {
  const SettlementsScreen({super.key});

  @override
  State<SettlementsScreen> createState() => _SettlementsScreenState();
}

class _SettlementsScreenState extends State<SettlementsScreen> {
  List<Map<String, dynamic>>? _items;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await getIt<SettlementRepository>().list();
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

  Future<void> _create() async {
    final l10n = context.l10n;
    final role = context.read<AuthCubit>().state.user?.role ?? UserRole.salesperson;
    if (!RolePermissions.canPerform(AppAction.settlementCreate, role)) return;

    List<CustomerModel> customers;
    try {
      customers = await loadCreditCustomers();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
      return;
    }

    if (!mounted) return;

    final result = await showDialog<
        ({String customerId, String date, String paymentMethod, String? notes})?>(
      context: context,
      builder: (ctx) => _RecordSettlementDialog(customers: customers),
    );

    if (result == null) return;

    try {
      await getIt<SettlementRepository>().create({
        'customer_id': result.customerId,
        'settlement_date': result.date,
        'payment_method': result.paymentMethod,
        if (result.notes != null && result.notes!.isNotEmpty)
          'notes': result.notes,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.settlementSaved)),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_settlementErrorMessage(context, e))),
      );
    }
  }

  String _settlementErrorMessage(BuildContext context, Object e) {
    final l10n = context.l10n;
    final msg = e.toString().toLowerCase();
    if (msg.contains('credit customers only') ||
        msg.contains('credit customer')) {
      return l10n.settlementCreditOnly;
    }
    if (msg.contains('no unpaid') || msg.contains('unpaid credit')) {
      return l10n.settlementNoUnpaidInvoices;
    }
    return e.toString();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final role = context.read<AuthCubit>().state.user?.role ?? UserRole.salesperson;
    final canCreate = RolePermissions.canPerform(AppAction.settlementCreate, role);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHeader(
          title: l10n.settlementsTitle,
          subtitle: l10n.settlementsSubtitle,
          actions: [
            IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
            if (canCreate)
              FilledButton.icon(
                onPressed: _create,
                icon: const Icon(Icons.add),
                label: Text(l10n.recordSettlement),
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
                        final s = _items![i];
                        final amount = s['amount'] ?? s['total_amount'];
                        final customer = s['customer'];
                        return EntityListTile(
                          title: customer is Map
                              ? '${customer['name']}'
                              : '${s['customer_id']}',
                          subtitle: l10n.settlementRowSubtitle(
                            '${s['settlement_date']}',
                            formatMoney(
                              context,
                              amount is num ? amount : null,
                            ),
                          ),
                          leading: const Icon(Icons.account_balance_wallet_outlined),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}

class _RecordSettlementDialog extends StatefulWidget {
  const _RecordSettlementDialog({required this.customers});

  final List<CustomerModel> customers;

  @override
  State<_RecordSettlementDialog> createState() => _RecordSettlementDialogState();
}

class _RecordSettlementDialogState extends State<_RecordSettlementDialog> {
  String? _customerId;
  String _paymentMethod = 'cash';
  final _date = TextEditingController(
    text: DateTime.now().toIso8601String().split('T').first,
  );
  final _notes = TextEditingController();

  @override
  void initState() {
    super.initState();
    final withBalance =
        widget.customers.where((c) => c.outstandingBalance > 0).toList();
    final list = withBalance.isNotEmpty ? withBalance : widget.customers;
    if (list.isNotEmpty) {
      _customerId = list.first.id;
    }
  }

  @override
  void dispose() {
    _date.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AlertDialog(
      title: Text(l10n.recordSettlement),
      titlePadding: kDialogTitlePadding,
      contentPadding: kDialogContentPadding,
      actionsPadding: kDialogActionsPadding,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  l10n.settlementCreditHint,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        height: 1.5,
                      ),
                ),
              ),
              if (widget.customers.isEmpty)
                Text(
                  l10n.noCreditCustomers,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                )
              else
                ...spacedFormFields([
                  CustomerDropdown(
                    customers: widget.customers,
                    value: _customerId,
                    label: l10n.selectCustomer,
                    onChanged: (v) => setState(() => _customerId = v),
                  ),
                  DropdownButtonFormField<String>(
                    value: _paymentMethod,
                    decoration: InputDecoration(labelText: l10n.paymentMethod),
                    isExpanded: true,
                    items: [
                      DropdownMenuItem(
                        value: 'cash',
                        child: Text(l10n.cash),
                      ),
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
                    controller: _date,
                    decoration: InputDecoration(labelText: l10n.date),
                  ),
                  TextField(
                    controller: _notes,
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
          onPressed: widget.customers.isEmpty || _customerId == null
              ? null
              : () {
                  Navigator.pop(
                    context,
                    (
                      customerId: _customerId!,
                      date: _date.text.trim(),
                      paymentMethod: _paymentMethod,
                      notes: _notes.text.trim(),
                    ),
                  );
                },
          child: Text(l10n.save),
        ),
      ],
    );
  }
}
