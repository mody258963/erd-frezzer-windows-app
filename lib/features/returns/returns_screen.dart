import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/auth/auth_cubit.dart';
import '../../core/auth/role_permissions.dart';
import '../../core/l10n/api_labels.dart';
import '../../core/l10n/l10n_extension.dart';
import '../../data/models/invoice_model.dart';
import '../../data/models/user_role.dart';
import '../../data/repositories/invoice_repository.dart';
import '../../data/repositories/return_repository.dart';
import '../../di/injection.dart';
import '../shared/entity_list_tile.dart';
import '../shared/form_field_spacing.dart';
import '../shared/loading_error.dart';
import '../shared/page_header.dart';
import '../shared/status_chip.dart';

class _ReturnLineDraft {
  _ReturnLineDraft({
    required this.partId,
    required this.maxQty,
    required this.unitPrice,
    this.partLabel,
  });

  final String partId;
  final int maxQty;
  final double unitPrice;
  final String? partLabel;
  int returnQty = 0;
  String condition = 'sellable';
}

class ReturnsScreen extends StatefulWidget {
  const ReturnsScreen({super.key});

  @override
  State<ReturnsScreen> createState() => _ReturnsScreenState();
}

class _ReturnsScreenState extends State<ReturnsScreen> {
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
      final items = await getIt<ReturnRepository>().list();
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

  String _invoiceLabel(BuildContext context, InvoiceModel inv) {
    final l10n = context.l10n;
    final shortId = inv.id.length > 8 ? '${inv.id.substring(0, 8)}…' : inv.id;
    final who = inv.customerName ?? inv.customerId;
    return l10n.invoicePickerLabel(
      shortId,
      who,
      formatMoney(context, inv.total),
    );
  }

  List<_ReturnLineDraft> _linesFromInvoice(InvoiceModel inv) {
    return [
      for (final line in inv.items)
        _ReturnLineDraft(
          partId: line.partId,
          maxQty: line.quantity,
          unitPrice: line.unitPrice ?? 0,
          partLabel: line.partCode != null
              ? '${line.partCode} — ${line.partName ?? line.partId}'
              : (line.partName ?? line.partId),
        ),
    ];
  }

  Future<void> _create() async {
    final l10n = context.l10n;
    final role = context.read<AuthCubit>().state.user?.role ?? UserRole.salesperson;
    if (!RolePermissions.canPerform(AppAction.returnCreate, role)) return;

    List<InvoiceModel> invoices;
    try {
      invoices = await getIt<InvoiceRepository>().list(perPage: 100);
      invoices = invoices
          .where((i) {
            final s = (i.status ?? '').toLowerCase();
            return s != 'cancelled' && s != 'canceled' && s != 'void';
          })
          .toList();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
      return;
    }

    if (invoices.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.noData)),
      );
      return;
    }

    if (!mounted) return;

    final result = await showDialog<({InvoiceModel invoice, String reason, List<_ReturnLineDraft> lines})?>(
      context: context,
      builder: (ctx) => _CreateReturnDialog(
        invoices: invoices,
        invoiceLabel: (inv) => _invoiceLabel(ctx, inv),
        linesFromInvoice: _linesFromInvoice,
      ),
    );

    if (result == null) return;
    final selectedInvoice = result.invoice;
    final lines = result.lines;

    final returnItems = <Map<String, dynamic>>[];
    for (final line in lines) {
      if (line.returnQty <= 0) continue;
      returnItems.add({
        'part_id': line.partId,
        'quantity': line.returnQty,
        'unit_price': line.unitPrice,
        'condition': line.condition,
      });
    }

    if (returnItems.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.selectReturnLines)),
      );
      return;
    }

    try {
      await getIt<ReturnRepository>().create({
        'return_type': 'customer_return',
        'reference_type': 'invoice',
        'reference_id': selectedInvoice.id,
        'customer_id': selectedInvoice.customerId,
        'branch_id': selectedInvoice.branchId,
        'reason': result.reason,
        'items': returnItems,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.returnSaved)),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<void> _reject(String id) async {
    final l10n = context.l10n;
    final reason = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.reject),
        content: TextField(
          controller: reason,
          decoration: InputDecoration(labelText: l10n.rejectReason),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.reject),
          ),
        ],
      ),
    );
    if (ok != true || reason.text.trim().isEmpty) {
      reason.dispose();
      return;
    }
    try {
      await getIt<ReturnRepository>().reject(id, reason: reason.text.trim());
      reason.dispose();
      await _load();
    } catch (e) {
      reason.dispose();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final role = context.read<AuthCubit>().state.user?.role ?? UserRole.salesperson;
    final canCreate = RolePermissions.canPerform(AppAction.returnCreate, role);
    final canApprove = RolePermissions.canPerform(AppAction.returnApprove, role);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHeader(
          title: l10n.returnsTitle,
          actions: [
            IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
            if (canCreate)
              FilledButton.icon(
                onPressed: _create,
                icon: const Icon(Icons.add),
                label: Text(l10n.newReturn),
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
                        final r = _items![i];
                        final id = r['id'] as String;
                        final status = r['status'] as String? ?? '';
                        final statusLabel = localizeApiStatus(context, status);
                        final typeLabel =
                            localizeReturnType(context, r['return_type'] as String?);
                        final customer = r['customer'] is Map
                            ? (r['customer'] as Map)['name'] as String?
                            : null;
                        final subtitle = [
                          if (customer != null) customer,
                          r['reason'] as String?,
                        ].whereType<String>().where((s) => s.isNotEmpty).join(' · ');

                        return EntityListTile(
                          title: l10n.returnRowTitle(typeLabel, statusLabel),
                          subtitle: subtitle.isEmpty ? null : subtitle,
                          leading: const Icon(Icons.undo_outlined),
                          trailing: status == 'pending' && canApprove
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    FilledButton.tonal(
                                      onPressed: () async {
                                        try {
                                          await getIt<ReturnRepository>()
                                              .approve(id);
                                          await _load();
                                        } catch (e) {
                                          if (!context.mounted) return;
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(content: Text('$e')),
                                          );
                                        }
                                      },
                                      child: Text(l10n.approve),
                                    ),
                                    const SizedBox(width: 8),
                                    OutlinedButton(
                                      onPressed: () => _reject(id),
                                      child: Text(l10n.reject),
                                    ),
                                  ],
                                )
                              : StatusChip(
                                  label: statusLabel,
                                  variant: status == 'approved'
                                      ? StatusChipVariant.success
                                      : StatusChipVariant.warning,
                                ),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}

class _CreateReturnDialog extends StatefulWidget {
  const _CreateReturnDialog({
    required this.invoices,
    required this.invoiceLabel,
    required this.linesFromInvoice,
  });

  final List<InvoiceModel> invoices;
  final String Function(InvoiceModel) invoiceLabel;
  final List<_ReturnLineDraft> Function(InvoiceModel) linesFromInvoice;

  @override
  State<_CreateReturnDialog> createState() => _CreateReturnDialogState();
}

class _CreateReturnDialogState extends State<_CreateReturnDialog> {
  late InvoiceModel _invoice;
  late List<_ReturnLineDraft> _lines;
  final _reason = TextEditingController();
  final _qtyControllers = <String, TextEditingController>{};
  bool _loadingInvoice = false;

  @override
  void initState() {
    super.initState();
    _invoice = widget.invoices.first;
    _lines = [];
    _loadInvoiceDetails(_invoice.id);
  }

  Future<void> _loadInvoiceDetails(String id) async {
    setState(() => _loadingInvoice = true);
    try {
      final full = await getIt<InvoiceRepository>().get(id);
      if (!mounted) return;
      setState(() {
        _invoice = full;
        _resetLines();
        _loadingInvoice = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingInvoice = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    }
  }

  @override
  void dispose() {
    _reason.dispose();
    for (final c in _qtyControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _resetLines() {
    for (final c in _qtyControllers.values) {
      c.dispose();
    }
    _qtyControllers.clear();
    _lines = widget.linesFromInvoice(_invoice);
    for (final line in _lines) {
      _qtyControllers[line.partId] = TextEditingController();
    }
  }

  void _submit() {
    final l10n = context.l10n;
    for (final line in _lines) {
      final q = int.tryParse(_qtyControllers[line.partId]?.text ?? '') ?? 0;
      line.returnQty = q.clamp(0, line.maxQty);
    }
    if (_lines.every((l) => l.returnQty <= 0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.selectReturnLines)),
      );
      return;
    }
    Navigator.pop(
      context,
      (
        invoice: _invoice,
        reason: _reason.text.trim(),
        lines: _lines,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AlertDialog(
      title: Text(l10n.newReturn),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: spacedFormFields([
              DropdownButtonFormField<String>(
                value: _invoice.id,
                decoration: InputDecoration(labelText: l10n.selectInvoice),
                isExpanded: true,
                items: [
                  for (final inv in widget.invoices)
                    DropdownMenuItem(
                      value: inv.id,
                      child: Text(widget.invoiceLabel(inv)),
                    ),
                ],
                onChanged: (id) {
                  if (id == null) return;
                  _loadInvoiceDetails(id);
                },
              ),
              if (_loadingInvoice)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Center(child: CircularProgressIndicator()),
                ),
              TextField(
                controller: _reason,
                decoration: InputDecoration(labelText: l10n.returnReason),
                maxLines: 2,
              ),
              if (_lines.isEmpty)
                Text(
                  l10n.noInvoiceLines,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                )
              else
                ..._lines.map((line) {
                  final qtyCtrl = _qtyControllers[line.partId]!;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            line.partLabel ?? line.partId,
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: qtyCtrl,
                                  decoration: InputDecoration(
                                    labelText:
                                        '${l10n.returnQty} (max ${line.maxQty})',
                                  ),
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: line.condition,
                                  decoration: InputDecoration(
                                    labelText: l10n.returnCondition,
                                  ),
                                  isExpanded: true,
                                  items: [
                                    DropdownMenuItem(
                                      value: 'sellable',
                                      child: Text(l10n.conditionSellable),
                                    ),
                                    DropdownMenuItem(
                                      value: 'defective',
                                      child: Text(l10n.conditionDefective),
                                    ),
                                  ],
                                  onChanged: (v) {
                                    if (v != null) {
                                      setState(() => line.condition = v);
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }),
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
          onPressed: _submit,
          child: Text(l10n.create),
        ),
      ],
    );
  }
}
