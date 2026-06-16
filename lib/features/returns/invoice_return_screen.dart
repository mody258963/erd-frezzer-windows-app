import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_cubit.dart';
import '../../core/auth/role_permissions.dart';
import '../../core/events/app_refresh_bus.dart';
import '../../core/l10n/api_labels.dart';
import '../../core/l10n/l10n_extension.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/return_approval_helper.dart';
import '../../core/utils/return_quantity_exception.dart';
import '../../core/utils/sale_quantity.dart';
import '../../data/models/invoice_model.dart';
import '../../data/models/user_role.dart';
import '../../data/repositories/invoice_repository.dart';
import '../../data/repositories/return_repository.dart';
import '../../di/injection.dart';
import '../shared/loading_error.dart';
import '../shared/status_chip.dart';

class _ReturnLineState {
  _ReturnLineState({
    required this.item,
    required this.partLabel,
  }) : returnQty = 0;

  final InvoiceItemModel item;
  final String partLabel;
  double returnQty = 0;
  String condition = 'sellable';
  bool selected = false;

  double get maxQty => item.availableForReturn;
  double get unitPrice => item.unitPrice ?? 0;
  double get lineRefund => returnQty * unitPrice;
}

class InvoiceReturnScreen extends StatefulWidget {
  const InvoiceReturnScreen({
    required this.invoiceId,
    super.key,
  });

  final String invoiceId;

  @override
  State<InvoiceReturnScreen> createState() => _InvoiceReturnScreenState();
}

class _InvoiceReturnScreenState extends State<InvoiceReturnScreen> {
  InvoiceModel? _invoice;
  List<_ReturnLineState> _lines = [];
  String? _error;
  bool _loading = true;
  bool _submitting = false;
  final _reason = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final inv = await getIt<InvoiceRepository>().get(widget.invoiceId);
      if (!mounted) return;
      setState(() {
        _invoice = inv;
        _lines = [
          for (final item in inv.items)
            _ReturnLineState(
              item: item,
              partLabel: item.partCode != null
                  ? '${item.partCode} — ${item.partName ?? item.partId}'
                  : (item.partName ?? item.partId),
            ),
        ];
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  double get _refundTotal =>
      _lines.fold(0.0, (s, l) => s + (l.selected ? l.lineRefund : 0));

  void _setLineQty(_ReturnLineState line, double qty) {
    setState(() {
      line.returnQty = qty.clamp(0, line.maxQty);
      line.selected = line.returnQty > 0;
    });
  }

  Future<void> _submit() async {
    final l10n = context.l10n;
    final inv = _invoice;
    if (inv == null) return;

    if (!inv.canCreateReturn) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.invoiceAlreadyReturned)),
      );
      return;
    }

    final returnItems = <Map<String, dynamic>>[];
    for (final line in _lines) {
      if (!line.selected || line.returnQty <= 0) continue;
      returnItems.add({
        'part_id': line.item.partId,
        'quantity': line.returnQty,
        'unit_price': line.unitPrice,
        'condition': line.condition,
      });
    }

    if (returnItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.selectReturnLines)),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      await getIt<ReturnRepository>().create(
        buildCustomerReturnBody(
          referenceId: inv.id,
          customerId: inv.customerId,
          branchId: inv.branchId,
          reason: _reason.text.trim().isEmpty
              ? l10n.returnTypeCustomer
              : _reason.text.trim(),
          items: returnItems,
        ),
      );
      if (!mounted) return;

      getIt<AppRefreshBus>().notify(AppRefreshKind.invoices);
      getIt<AppRefreshBus>().notify(AppRefreshKind.dashboard);
      getIt<AppRefreshBus>().notify(AppRefreshKind.inventory);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.returnSaved)),
      );
      context.pop(true);
    } on DioException catch (e) {
      if (!mounted) return;
      final rq = parseReturnQuantityException(e);
      if (rq != null && rq.failures.isNotEmpty) {
        final f = rq.failures.first;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.returnQuantityExceeded(f.available)),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? e.toString())),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final role = context.read<AuthCubit>().state.user?.role ?? UserRole.salesperson;
    final canCreate = RolePermissions.canPerform(AppAction.returnCreate, role);

    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.returnItemsTitle)),
        body: const LoadingView(),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.returnItemsTitle)),
        body: ErrorView(message: _error!, onRetry: _load),
      );
    }

    final inv = _invoice!;

    return Scaffold(
      appBar: AppBar(
        title: Text('${l10n.returnItemsTitle} — ${inv.displayNumber}'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          inv.customerName ?? inv.customerId,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        if (inv.returnStatus != null &&
                            inv.returnStatus!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          StatusChip(
                            label: localizeInvoiceReturnStatus(
                              context,
                              inv.returnStatus,
                            ),
                            variant: inv.isReturned
                                ? StatusChipVariant.warning
                                : StatusChipVariant.info,
                          ),
                        ],
                        if (inv.isReturned)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              l10n.invoiceAlreadyReturned,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _reason,
                  decoration: InputDecoration(labelText: l10n.returnReason),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                if (_lines.isEmpty)
                  Text(
                    l10n.noInvoiceLines,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  )
                else
                  ..._lines.map((line) => _ReturnLineCard(
                        line: line,
                        enabled: inv.canCreateReturn && line.maxQty > 0,
                        onChanged: () => setState(() {}),
                        onQtyChanged: (q) => _setLineQty(line, q),
                      )),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              border: Border(top: BorderSide(color: AppColors.outline)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.returnRefundTotal,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    Text(
                      formatMoney(context, _refundTotal),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _submitting ? null : () => context.pop(),
                        child: Text(l10n.cancel),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: canCreate &&
                                inv.canCreateReturn &&
                                !_submitting
                            ? _submit
                            : null,
                        child: _submitting
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text(l10n.create),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReturnLineCard extends StatelessWidget {
  const _ReturnLineCard({
    required this.line,
    required this.enabled,
    required this.onChanged,
    required this.onQtyChanged,
  });

  final _ReturnLineState line;
  final bool enabled;
  final VoidCallback onChanged;
  final ValueChanged<double> onQtyChanged;

  double _returnStep() {
    if (line.maxQty < 1 || line.maxQty != line.maxQty.roundToDouble()) {
      return 0.25;
    }
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final item = line.item;
    final step = _returnStep();

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Checkbox(
                  value: line.selected && line.returnQty > 0,
                  onChanged: enabled
                      ? (v) {
                          if (v == true) {
                            onQtyChanged(
                              line.returnQty > 0
                                  ? line.returnQty
                                  : (line.maxQty < step ? line.maxQty : step),
                            );
                          } else {
                            onQtyChanged(0);
                          }
                          onChanged();
                        }
                      : null,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        line.partLabel,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.soldQtyLabel(item.soldQty),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        l10n.availableQtyLabel(line.maxQty),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: line.maxQty > 0
                                  ? AppColors.success
                                  : Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                            ),
                      ),
                      if (item.quantityReturnedCompleted > 0 ||
                          item.quantityReturnedPending > 0)
                        Text(
                          l10n.returnedQtyLabel(
                            item.quantityReturnedCompleted,
                            item.quantityReturnedPending,
                          ),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                    ],
                  ),
                ),
              ],
            ),
            if (enabled) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  IconButton(
                    onPressed: line.returnQty > 0
                        ? () => onQtyChanged(
                              (line.returnQty - step).clamp(0, line.maxQty),
                            )
                        : null,
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                  Text(
                    formatSaleQuantity(line.returnQty),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  IconButton(
                    onPressed: line.returnQty + step <= line.maxQty + 1e-9
                        ? () => onQtyChanged(
                              (line.returnQty + step).clamp(0, line.maxQty),
                            )
                        : null,
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: 140,
                    child: DropdownButtonFormField<String>(
                      initialValue: line.condition,
                      decoration: InputDecoration(
                        labelText: l10n.returnCondition,
                        isDense: true,
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
                          line.condition = v;
                          onChanged();
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
