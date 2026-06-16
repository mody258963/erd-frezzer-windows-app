import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_cubit.dart';
import '../../core/auth/role_permissions.dart';
import '../../core/branch/branch_filter_scope.dart';
import '../../core/events/app_refresh_bus.dart';
import '../../core/l10n/api_labels.dart';
import '../../core/l10n/l10n_extension.dart';
import '../../core/printer/printer_print_helper.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/balance_parse.dart';
import '../../core/utils/business_week.dart';
import '../../data/models/customer_model.dart';
import '../../data/models/invoice_model.dart';
import '../../data/models/linked_balance_model.dart';
import '../../data/models/supplier_model.dart';
import '../../data/models/user_role.dart';
import '../../data/repositories/customer_repository.dart';
import '../../data/repositories/supplier_repository.dart';
import '../../di/injection.dart';
import '../dashboard/widgets/dashboard_section.dart';
import '../shared/entity_detail_widgets.dart';
import '../shared/form_field_spacing.dart';
import '../shared/loading_error.dart';
import '../shared/page_header.dart';
import '../shared/settlement_cycle_dropdown.dart';
import 'collect_payment_dialog.dart';
import 'edit_payment_dialog.dart';
import 'offset_supplier_dialog.dart';
import 'widgets/linked_balance_card.dart';

class _PurchaseLine {
  const _PurchaseLine({
    required this.invoiceId,
    required this.partCode,
    required this.partName,
    required this.quantity,
    required this.lineTotal,
    required this.date,
    required this.branchLabel,
  });

  final String invoiceId;
  final String partCode;
  final String partName;
  final double quantity;
  final double lineTotal;
  final String date;
  final String branchLabel;
}

class CustomerDetailScreen extends StatefulWidget {
  const CustomerDetailScreen({required this.customerId, super.key});

  final String customerId;

  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen> {
  CustomerModel? _customer;
  double _balance = 0;
  List<InvoiceModel> _invoices = [];
  LinkedBalanceModel? _linkedBalance;
  List<Map<String, dynamic>> _payments = [];
  String? _error;
  bool _loading = true;
  bool _viewThisWeek = true;

  @override
  void initState() {
    super.initState();
    getIt<AppRefreshBus>().addListener(_onAppRefresh);
    _load();
  }

  @override
  void dispose() {
    getIt<AppRefreshBus>().removeListener(_onAppRefresh);
    super.dispose();
  }

  void _onAppRefresh(AppRefreshKind kind) {
    if (!mounted) return;
    if (kind == AppRefreshKind.invoices ||
        kind == AppRefreshKind.settlements ||
        kind == AppRefreshKind.branchFilter) {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = getIt<CustomerRepository>();
      final customer = await repo.get(widget.customerId);
      final balanceMap = await repo.balance(widget.customerId);
      final invoices = await repo.invoices(widget.customerId);
      LinkedBalanceModel? linked;
      try {
        linked = await repo.linkedBalance(widget.customerId);
      } catch (_) {}
      List<Map<String, dynamic>> payments = [];
      try {
        payments = await repo.payments(widget.customerId);
      } catch (_) {}
      if (!mounted) return;
      setState(() {
        _customer = customer;
        _balance = parseOutstandingBalance(balanceMap);
        _invoices = invoices;
        _linkedBalance = linked;
        _payments = payments;
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

  DateTimeRange get _weekRange => BusinessWeek.rangeFor(DateTime.now());

  String _formatDate(String? raw) {
    if (raw == null || raw.isEmpty) return '—';
    final dt = DateTime.tryParse(raw);
    if (dt == null) return raw;
    return BusinessWeek.isoDate(dt.toLocal());
  }

  String _weekRangeLabel(BuildContext context) {
    final l10n = context.l10n;
    return l10n.customerWeekRange(
      _formatDate(_weekRange.start.toIso8601String()),
      _formatDate(_weekRange.end.toIso8601String()),
    );
  }

  bool _isOpenThisWeek(InvoiceModel inv) {
    if (inv.isSettled) return false;
    return BusinessWeek.isWithinWeek(inv.createdAt, _weekRange);
  }

  bool _isHistory(InvoiceModel inv) {
    if (inv.isSettled) return true;
    final dt = BusinessWeek.parseInvoiceDate(inv.createdAt);
    if (dt == null) return false;
    return dt.isBefore(_weekRange.start);
  }

  List<InvoiceModel> get _filteredInvoices {
    if (_viewThisWeek) {
      return _invoices.where(_isOpenThisWeek).toList();
    }
    return _invoices.where(_isHistory).toList();
  }

  List<_PurchaseLine> _purchaseLines(List<InvoiceModel> invoices) {
    final lines = <_PurchaseLine>[];
    for (final inv in invoices) {
      final branch = inv.branchName ?? inv.branchId;
      final date = inv.createdAt ?? '';
      for (final item in inv.items) {
        lines.add(
          _PurchaseLine(
            invoiceId: inv.id,
            partCode: item.partCode ?? item.partId,
            partName: item.partName ?? item.partId,
            quantity: item.quantity,
            lineTotal: item.lineTotal ??
                (item.unitPrice ?? 0) * item.quantity,
            date: date,
            branchLabel: branch,
          ),
        );
      }
    }
    return lines;
  }

  double get _purchaseTotal =>
      _purchaseLines(_filteredInvoices).fold(0, (sum, line) => sum + line.lineTotal);

  List<Map<String, dynamic>> get _sortedPayments {
    final copy = List<Map<String, dynamic>>.from(_payments);
    copy.sort((a, b) {
      final da = '${a['created_at'] ?? a['paid_at'] ?? ''}';
      final db = '${b['created_at'] ?? b['paid_at'] ?? ''}';
      return db.compareTo(da);
    });
    return copy;
  }

  Future<void> _collectPayment(BuildContext context, CustomerModel customer) async {
    final l10n = context.l10n;
    final result = await CollectPaymentDialog.show(
      context,
      customerName: customer.name,
      outstandingBalance: _balance,
    );
    if (result == null) return;
    try {
      await getIt<CustomerRepository>().collectPayment(
        customer.id,
        paymentMethod: result.paymentMethod,
        amount: result.payFullBalance ? null : result.amount,
        notes: result.notes,
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.collectPaymentSuccess)),
      );
      await _load();
      getIt<AppRefreshBus>().notify(AppRefreshKind.settlements);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<void> _editLatestPayment(BuildContext context) async {
    final l10n = context.l10n;
    final customer = _customer;
    if (customer == null || customer.type != 'credit') return;

    final role = context.read<AuthCubit>().state.user?.role ?? UserRole.salesperson;
    if (!RolePermissions.canPerform(AppAction.paymentEdit, role)) return;
    if (_sortedPayments.isEmpty) return;

    final latest = _sortedPayments.first;
    final paymentId = latest['id'] as String?;
    if (paymentId == null || paymentId.isEmpty) return;

    final currentAmount = (latest['amount'] as num?)?.toDouble() ?? 0;
    final currentMethod =
        latest['payment_method'] as String? ?? 'cash';
    final currentNotes = latest['notes'] as String?;

    final result = await EditPaymentDialog.show(
      context,
      currentAmount: currentAmount,
      paymentMethod: currentMethod,
      notes: currentNotes,
    );
    if (result == null) return;

    try {
      await getIt<CustomerRepository>().updatePayment(
        widget.customerId,
        paymentId,
        amount: result.amount,
        paymentMethod: result.paymentMethod,
        notes: result.notes,
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.paymentUpdated)),
      );
      await _load();
      getIt<AppRefreshBus>().notify(AppRefreshKind.settlements);
      getIt<AppRefreshBus>().notify(AppRefreshKind.invoices);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<void> _offsetSupplier(BuildContext context) async {
    final lb = _linkedBalance;
    if (lb == null || !lb.isLinked) return;
    final l10n = context.l10n;
    final result = await OffsetSupplierDialog.show(context, lb);
    if (result == null) return;
    try {
      await getIt<CustomerRepository>().offsetSupplier(
        widget.customerId,
        amount: result.offsetFull ? null : result.amount,
        notes: result.notes,
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.offsetSuccess)),
      );
      await _load();
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<void> _printWeekInvoices(BuildContext context) async {
    final l10n = context.l10n;
    final weekInvoices = _invoices.where(_isOpenThisWeek).toList();
    if (weekInvoices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.customerNoWeekInvoices)),
      );
      return;
    }
    try {
      await printInvoicesBatch(weekInvoices);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.weekInvoicesPrinted('${weekInvoices.length}'))),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.printFailed(e.toString()))),
      );
    }
  }

  Future<void> _editCustomer(BuildContext context, CustomerModel customer) async {
    final l10n = context.l10n;
    final role = context.read<AuthCubit>().state.user?.role ?? UserRole.salesperson;
    final canLink = RolePermissions.canPerform(AppAction.settlementCreate, role);

    List<SupplierModel> suppliers = [];
    if (canLink) {
      try {
        suppliers = await getIt<SupplierRepository>().list(
          branchId: apiBranchIdFromContext(context),
        );
      } catch (_) {}
    }

    final name = TextEditingController(text: customer.name);
    final type = ValueNotifier(customer.type);
    final settlementCycle =
        ValueNotifier(customer.settlementCycle ?? 'weekly');
    final phone = TextEditingController(text: customer.phone ?? '');
    final address = TextEditingController(text: customer.address ?? '');
    final creditLimit =
        TextEditingController(text: '${customer.creditLimit}');
    final linkedSupplierId = ValueNotifier<String?>(customer.linkedSupplierId);
    final supplierIds = suppliers.map((s) => s.id).toSet();
    final safeLinkedId = linkedSupplierId.value != null &&
            supplierIds.contains(linkedSupplierId.value)
        ? linkedSupplierId.value
        : null;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.editCustomer),
        content: SizedBox(
          width: 400,
          child: ValueListenableBuilder(
            valueListenable: type,
            builder: (ctx, t, _) => ValueListenableBuilder(
              valueListenable: linkedSupplierId,
              builder: (ctx, linkedId, _) => ValueListenableBuilder(
                valueListenable: settlementCycle,
                builder: (ctx, cycle, _) => Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: spacedFormFields([
                    TextField(
                      controller: name,
                      decoration: InputDecoration(labelText: l10n.name),
                    ),
                    DropdownButtonFormField<String>(
                      initialValue: t,
                      decoration: InputDecoration(labelText: l10n.customerType),
                      items: [
                        DropdownMenuItem(value: 'cash', child: Text(l10n.cash)),
                        DropdownMenuItem(
                          value: 'credit',
                          child: Text(l10n.credit),
                        ),
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
                    if (canLink && t == 'credit')
                      DropdownButtonFormField<String?>(
                        initialValue: safeLinkedId,
                        decoration: InputDecoration(
                          labelText: l10n.linkToSupplier,
                        ),
                        isExpanded: true,
                        items: [
                          DropdownMenuItem<String?>(
                            value: null,
                            child: Text(l10n.noLinkedSupplier),
                          ),
                          for (final s in suppliers)
                            DropdownMenuItem(
                              value: s.id,
                              child: Text(s.name),
                            ),
                        ],
                        onChanged: (v) => linkedSupplierId.value = v,
                      ),
                  ]),
                ),
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
      if (canLink && type.value == 'credit')
        'linked_supplier_id': linkedSupplierId.value,
    };
    try {
      await getIt<CustomerRepository>().update(customer.id, body);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.customerSaved)),
      );
      await _load();
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final role = context.read<AuthCubit>().state.user?.role ?? UserRole.salesperson;
    final canSettle = RolePermissions.canPerform(AppAction.settlementCreate, role);
    final canEditPayment = RolePermissions.canPerform(AppAction.paymentEdit, role);
    final sortedPayments = _sortedPayments;

    if (_loading) return const Scaffold(body: LoadingView());
    if (_error != null) {
      return Scaffold(
        body: ErrorView(message: _error!, onRetry: _load),
      );
    }

    final customer = _customer!;
    final filtered = _filteredInvoices;
    final purchaseLines = _purchaseLines(filtered);
    final isCredit = customer.type == 'credit';

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PageHeader(
            title: customer.name,
            actions: [
              IconButton(
                tooltip: l10n.edit,
                onPressed: () => _editCustomer(context, customer),
                icon: const Icon(Icons.edit_outlined),
              ),
              OutlinedButton.icon(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.arrow_back),
                label: Text(l10n.close),
              ),
            ],
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  EntityProfileHeader(
                    title: customer.name,
                    subtitle: localizeCustomerType(context, customer.type),
                    leading: CircleAvatar(
                      child: Text(
                        customer.name.isNotEmpty
                            ? customer.name[0].toUpperCase()
                            : '?',
                      ),
                    ),
                    chips: [
                      Chip(
                        label: Text(
                          '${l10n.balance}: ${formatMoney(context, _balance)}',
                        ),
                      ),
                      if (isCredit && customer.creditLimit > 0)
                        Chip(
                          label: Text(
                            '${l10n.creditLimit}: ${formatMoney(context, customer.creditLimit)}',
                          ),
                        ),
                      if (customer.settlementCycle != null)
                        Chip(
                          label: Text(
                            customer.settlementCycle == 'daily'
                                ? l10n.settlementCycleDaily
                                : l10n.settlementCycleWeekly,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (customer.phone != null && customer.phone!.isNotEmpty)
                    DetailField(
                      label: l10n.phoneNumber,
                      value: customer.phone!,
                      icon: Icons.phone_outlined,
                    ),
                  if (customer.address != null && customer.address!.isNotEmpty)
                    DetailField(
                      label: l10n.supplierAddress,
                      value: customer.address!,
                      icon: Icons.location_on_outlined,
                    ),
                  if (isCredit && canSettle) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        FilledButton.icon(
                          onPressed: _balance > 0
                              ? () => _collectPayment(context, customer)
                              : null,
                          icon: const Icon(Icons.payments_outlined),
                          label: Text(l10n.collectPaymentTitle),
                        ),
                        if (_viewThisWeek)
                          OutlinedButton.icon(
                            onPressed: () => _printWeekInvoices(context),
                            icon: const Icon(Icons.print_outlined),
                            label: Text(l10n.printWeekInvoices),
                          ),
                      ],
                    ),
                  ],
                  if (_linkedBalance != null) ...[
                    const SizedBox(height: 16),
                    LinkedBalanceCard(
                      linkedBalance: _linkedBalance!,
                      onOffset: canSettle ? () => _offsetSupplier(context) : null,
                    ),
                  ],
                  const SizedBox(height: 20),
                  SegmentedButton<bool>(
                    segments: [
                      ButtonSegment(
                        value: true,
                        label: Text(l10n.customerViewThisWeek),
                      ),
                      ButtonSegment(
                        value: false,
                        label: Text(l10n.customerViewHistory),
                      ),
                    ],
                    selected: {_viewThisWeek},
                    onSelectionChanged: (values) {
                      setState(() => _viewThisWeek = values.first);
                    },
                  ),
                  const SizedBox(height: 12),
                  DashboardSection(
                    title: _viewThisWeek
                        ? l10n.customerOpenWork
                        : l10n.customerSettledHistory,
                    subtitle: _viewThisWeek
                        ? l10n.customerThisWeekHint(_weekRangeLabel(context))
                        : l10n.customerSettledHistoryHint,
                    trailing: Text(
                      '${l10n.totalPurchases}: ${formatMoney(context, _purchaseTotal)}',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    child: const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.tapRowForInvoice,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 8),
                  if (filtered.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Text(
                        _viewThisWeek
                            ? l10n.customerNoOpenWorkThisWeek
                            : l10n.customerNoSettledHistory,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                    )
                  else ...[
                    _InvoicesTable(
                      invoices: filtered,
                      onTap: (id) => context.push('/invoices/$id'),
                    ),
                    const SizedBox(height: 20),
                    DashboardSection(
                      title: l10n.purchaseHistory,
                      subtitle: l10n.purchaseHistoryHint,
                      child: const SizedBox.shrink(),
                    ),
                    const SizedBox(height: 8),
                    if (purchaseLines.isEmpty)
                      Text(l10n.noPurchaseHistory)
                    else
                      _PurchaseLinesTable(
                        lines: purchaseLines,
                        onTapInvoice: (id) => context.push('/invoices/$id'),
                      ),
                  ],
                  if (sortedPayments.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    DashboardSection(
                      title: l10n.customerPaymentHistory,
                      child: const SizedBox.shrink(),
                    ),
                    const SizedBox(height: 8),
                    for (var i = 0; i < sortedPayments.length; i++)
                      Builder(
                        builder: (context) {
                          final p = sortedPayments[i];
                          final amount = (p['amount'] as num?)?.toDouble() ?? 0;
                          final method = p['payment_method'] as String?;
                          final date =
                              '${p['created_at'] ?? p['paid_at'] ?? ''}';
                          final subtitle = method != null && method.isNotEmpty
                              ? '${localizePaymentType(context, method)} · $date'
                              : date;
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.receipt_long_outlined),
                            title: Text(formatMoney(context, amount)),
                            subtitle: Text(subtitle),
                            trailing: canEditPayment && isCredit && i == 0
                                ? IconButton(
                                    tooltip: l10n.editPayment,
                                    icon: const Icon(Icons.edit_outlined),
                                    onPressed: () =>
                                        _editLatestPayment(context),
                                  )
                                : null,
                          );
                        },
                      ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InvoicesTable extends StatelessWidget {
  const _InvoicesTable({
    required this.invoices,
    required this.onTap,
  });

  final List<InvoiceModel> invoices;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final rowHeight = 52.0;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: 48 + invoices.length * rowHeight,
        child: DataTable2(
          headingRowHeight: 48,
          dataRowHeight: rowHeight,
          columnSpacing: 16,
          horizontalMargin: 16,
          minWidth: 720,
          columns: [
            DataColumn2(label: Text(l10n.invoiceNumber)),
            DataColumn2(label: Text(l10n.date)),
            DataColumn2(label: Text(l10n.total), numeric: true),
            DataColumn2(label: Text(l10n.balance), numeric: true),
            DataColumn2(label: Text(l10n.settled)),
          ],
          rows: [
            for (final inv in invoices)
              DataRow2(
                onTap: () => onTap(inv.id),
                cells: [
                  DataCell(Text(inv.displayNumber)),
                  DataCell(Text(inv.createdAt ?? '—')),
                  DataCell(Text(formatMoney(context, inv.total))),
                  DataCell(Text(formatMoney(context, inv.invoiceBalanceDue))),
                  DataCell(
                    Text(
                      inv.isSettled ? l10n.settled : l10n.statusOpen,
                      style: TextStyle(
                        color: inv.isSettled
                            ? AppColors.success
                            : AppColors.warning,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _PurchaseLinesTable extends StatelessWidget {
  const _PurchaseLinesTable({
    required this.lines,
    required this.onTapInvoice,
  });

  final List<_PurchaseLine> lines;
  final ValueChanged<String> onTapInvoice;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final rowHeight = 52.0;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: 48 + lines.length * rowHeight,
        child: DataTable2(
          headingRowHeight: 48,
          dataRowHeight: rowHeight,
          columnSpacing: 12,
          horizontalMargin: 16,
          minWidth: 900,
          columns: [
            DataColumn2(label: Text(l10n.code)),
            DataColumn2(label: Text(l10n.name)),
            DataColumn2(label: Text(l10n.quantity), numeric: true),
            DataColumn2(label: Text(l10n.total), numeric: true),
            DataColumn2(label: Text(l10n.date)),
            DataColumn2(label: Text(l10n.branch)),
          ],
          rows: [
            for (final row in lines)
              DataRow2(
                onTap: () => onTapInvoice(row.invoiceId),
                cells: [
                  DataCell(Text(row.partCode)),
                  DataCell(Text(row.partName)),
                  DataCell(Text('${row.quantity}')),
                  DataCell(Text(formatMoney(context, row.lineTotal))),
                  DataCell(Text(row.date)),
                  DataCell(Text(row.branchLabel)),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
