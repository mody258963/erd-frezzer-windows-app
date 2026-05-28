import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/auth/auth_cubit.dart';
import '../../core/auth/role_permissions.dart';
import '../../core/l10n/api_labels.dart';
import '../../core/l10n/l10n_extension.dart';
import '../../data/models/part_model.dart';
import '../../data/models/user_role.dart';
import '../../data/repositories/part_repository.dart';
import '../../data/repositories/purchase_repository.dart';
import '../../data/repositories/supplier_repository.dart';
import '../../di/injection.dart';
import '../shared/entity_list_tile.dart';
import '../shared/loading_error.dart';
import '../shared/page_header.dart';

class _PurchaseLineDraft {
  String? partId;
  int quantity = 1;
  double unitCost = 0;
}

class PurchasesScreen extends StatefulWidget {
  const PurchasesScreen({super.key});

  @override
  State<PurchasesScreen> createState() => _PurchasesScreenState();
}

class _PurchasesScreenState extends State<PurchasesScreen> {
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
      final items = await getIt<PurchaseRepository>().list();
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

  Future<void> _showCreateForm(BuildContext context) async {
    final l10n = context.l10n;
    final role = context.read<AuthCubit>().state.user?.role ?? UserRole.salesperson;
    if (!RolePermissions.canPerform(AppAction.purchaseCreate, role)) return;

    final branchId = context.read<AuthCubit>().state.user?.branchId;

    List<Map<String, dynamic>> suppliers = [];
    List<PartModel> parts = [];
    try {
      suppliers = await getIt<SupplierRepository>().list();
      parts = await getIt<PartRepository>().list(perPage: 200);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
      return;
    }

    if (!context.mounted) return;

    String? supplierId = suppliers.isNotEmpty ? suppliers.first['id'] as String? : null;
    String? selectedBranchId = branchId;
    final description = TextEditingController();
    String paymentType = 'immediate';
    int installmentCount = 3;
    final installmentStart = TextEditingController(
      text: DateTime.now().add(const Duration(days: 30)).toIso8601String().split('T').first,
    );
    final lines = <_PurchaseLineDraft>[_PurchaseLineDraft()];

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: Text(l10n.newPurchase),
            content: SizedBox(
              width: 520,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (suppliers.isEmpty)
                      Text(
                        l10n.noSuppliersHint,
                        style: TextStyle(color: Theme.of(ctx).colorScheme.error),
                      )
                    else
                      DropdownButtonFormField<String>(
                        value: supplierId,
                        decoration: InputDecoration(labelText: l10n.supplier),
                        items: [
                          for (final s in suppliers)
                            DropdownMenuItem(
                              value: s['id'] as String,
                              child: Text(s['name'] as String? ?? ''),
                            ),
                        ],
                        onChanged: (v) => setDialogState(() => supplierId = v),
                      ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: description,
                      decoration: InputDecoration(labelText: l10n.description),
                    ),
                    const SizedBox(height: 12),
                    SegmentedButton<String>(
                      segments: [
                        ButtonSegment(value: 'immediate', label: Text(l10n.paymentImmediate)),
                        ButtonSegment(value: 'installments', label: Text(l10n.paymentInstallments)),
                      ],
                      selected: {paymentType},
                      onSelectionChanged: (s) =>
                          setDialogState(() => paymentType = s.first),
                    ),
                    if (paymentType == 'installments') ...[
                      const SizedBox(height: 12),
                      TextField(
                        decoration: InputDecoration(labelText: l10n.installmentCount),
                        keyboardType: TextInputType.number,
                        onChanged: (v) => installmentCount = int.tryParse(v) ?? 3,
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: installmentStart,
                        decoration: InputDecoration(labelText: l10n.installmentStartDate),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Text(l10n.lineItems, style: Theme.of(ctx).textTheme.titleSmall),
                    const SizedBox(height: 8),
                    for (var i = 0; i < lines.length; i++) ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 3,
                            child: DropdownButtonFormField<String>(
                              value: lines[i].partId,
                              decoration: InputDecoration(labelText: l10n.part),
                              items: [
                                for (final p in parts)
                                  DropdownMenuItem(
                                    value: p.id,
                                    child: Text('${p.code} — ${p.name}'),
                                  ),
                              ],
                              onChanged: (v) {
                                setDialogState(() {
                                  lines[i].partId = v;
                                  final part = parts.where((p) => p.id == v).firstOrNull;
                                  if (part != null) {
                                    lines[i].unitCost = part.costPrice;
                                  }
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              decoration: InputDecoration(labelText: l10n.qty),
                              keyboardType: TextInputType.number,
                              controller: TextEditingController(text: '${lines[i].quantity}'),
                              onChanged: (v) => lines[i].quantity = int.tryParse(v) ?? 1,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              decoration: InputDecoration(labelText: l10n.unitCost),
                              keyboardType: TextInputType.number,
                              controller: TextEditingController(text: '${lines[i].unitCost}'),
                              onChanged: (v) =>
                                  lines[i].unitCost = double.tryParse(v) ?? 0,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: lines.length > 1
                                ? () => setDialogState(() => lines.removeAt(i))
                                : null,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                    OutlinedButton.icon(
                      onPressed: () => setDialogState(() => lines.add(_PurchaseLineDraft())),
                      icon: const Icon(Icons.add),
                      label: Text(l10n.addLine),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(l10n.cancel),
              ),
              FilledButton(
                onPressed: suppliers.isEmpty || supplierId == null
                    ? null
                    : () => Navigator.pop(ctx, true),
                child: Text(l10n.save),
              ),
            ],
          );
        },
      ),
    );

    if (ok != true || supplierId == null) {
      description.dispose();
      installmentStart.dispose();
      return;
    }

    if (selectedBranchId == null || selectedBranchId.isEmpty) {
      description.dispose();
      installmentStart.dispose();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.branchRequired)),
        );
      }
      return;
    }

    final validLines = lines.where((l) => l.partId != null && l.quantity > 0).toList();
    if (validLines.isEmpty) {
      description.dispose();
      installmentStart.dispose();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.addAtLeastOneLine)),
        );
      }
      return;
    }

    final body = <String, dynamic>{
      'supplier_id': supplierId,
      'branch_id': selectedBranchId,
      'description': description.text.trim(),
      'payment_type': paymentType,
      'items': [
        for (final l in validLines)
          {
            'part_id': l.partId,
            'quantity': l.quantity,
            'unit_cost': l.unitCost,
          },
      ],
    };
    if (paymentType == 'installments') {
      body['installment_count'] = installmentCount;
      body['installment_start_date'] = installmentStart.text.trim();
    }

    description.dispose();
    installmentStart.dispose();

    try {
      await getIt<PurchaseRepository>().create(body);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.purchaseSaved)),
        );
      }
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final role = context.read<AuthCubit>().state.user?.role ?? UserRole.salesperson;
    final canCreate = RolePermissions.canPerform(AppAction.purchaseCreate, role);
    final canReceive = RolePermissions.canPerform(AppAction.purchaseReceive, role);
    final canCancel = RolePermissions.canPerform(AppAction.purchaseCancel, role);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeader(
          title: l10n.purchasesTitle,
          actions: [
            IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
            if (canCreate)
              FilledButton.icon(
                onPressed: () => _showCreateForm(context),
                icon: const Icon(Icons.add),
                label: Text(l10n.newPurchase),
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
                        final p = _items![i];
                        final id = p['id'] as String;
                        final status = p['status'] as String? ?? '';
                        final supplierName =
                            p['supplier'] is Map ? (p['supplier'] as Map)['name'] : null;
                        return EntityListTile(
                          title: '${l10n.purchaseOrder} ${id.length > 8 ? id.substring(0, 8) : id}',
                          subtitle:
                              '${supplierName ?? ''} · ${localizeApiStatus(context, status)}',
                          leading: CircleAvatar(
                            backgroundColor:
                                Theme.of(context).colorScheme.primaryContainer,
                            child: Icon(
                              Icons.shopping_cart_outlined,
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (canReceive && status != 'received')
                                TextButton(
                                  onPressed: () async {
                                    try {
                                      await getIt<PurchaseRepository>().receive(id);
                                      await _load();
                                    } catch (e) {
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text(e.toString())),
                                        );
                                      }
                                    }
                                  },
                                  child: Text(l10n.receive),
                                ),
                              if (canCancel && status == 'pending')
                                IconButton(
                                  icon: const Icon(Icons.cancel_outlined),
                                  onPressed: () async {
                                    try {
                                      await getIt<PurchaseRepository>().cancel(id);
                                      await _load();
                                    } catch (e) {
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text(e.toString())),
                                        );
                                      }
                                    }
                                  },
                                ),
                            ],
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull {
    final it = iterator;
    if (!it.moveNext()) return null;
    return it.current;
  }
}
