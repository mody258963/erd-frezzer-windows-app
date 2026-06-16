import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/auth/auth_cubit.dart';
import '../../core/auth/role_permissions.dart';
import '../../core/events/app_refresh_bus.dart';
import '../../core/l10n/api_labels.dart';
import '../../core/l10n/l10n_extension.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/customer_model.dart';
import '../../data/models/settlement_upcoming_model.dart';
import '../../data/models/user_role.dart';
import '../../data/repositories/customer_repository.dart';
import '../../data/repositories/settlement_repository.dart';
import '../../di/injection.dart';
import '../customers/collect_payment_dialog.dart';
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
  static const _historyTab = 1;

  List<SettlementUpcomingRow>? _dueItems;
  List<Map<String, dynamic>>? _historyItems;
  String? _error;
  bool _loading = true;
  int _tabIndex = 0;
  String? _cycleFilter;

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
    if (kind == AppRefreshKind.branchFilter ||
        kind == AppRefreshKind.settlements) {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = getIt<SettlementRepository>();
      final due = await repo.upcoming(settlementCycle: _cycleFilter);
      final history = await repo.list();
      setState(() {
        _dueItems = due;
        _historyItems = history;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _create({String? initialCustomerId}) async {
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
      builder: (ctx) => _RecordSettlementDialog(
        customers: customers,
        initialCustomerId: initialCustomerId,
      ),
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
      getIt<AppRefreshBus>().notify(AppRefreshKind.dashboard);
      getIt<AppRefreshBus>().notify(AppRefreshKind.settlements);
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_settlementErrorMessage(context, e))),
      );
    }
  }

  Future<void> _partialPay(SettlementUpcomingRow row) async {
    final l10n = context.l10n;
    final role = context.read<AuthCubit>().state.user?.role ?? UserRole.salesperson;
    if (!RolePermissions.canPerform(AppAction.settlementCreate, role)) return;

    final result = await CollectPaymentDialog.show(
      context,
      customerName: row.customerName,
      outstandingBalance: row.amountDue,
    );
    if (result == null || !mounted) return;

    try {
      await getIt<CustomerRepository>().collectPayment(
        row.customerId,
        paymentMethod: result.paymentMethod,
        amount: result.payFullBalance ? null : result.amount,
        notes: result.notes,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.collectPaymentSuccess),
          backgroundColor: Colors.green.shade700,
        ),
      );
      getIt<AppRefreshBus>().notify(AppRefreshKind.dashboard);
      getIt<AppRefreshBus>().notify(AppRefreshKind.settlements);
      await _load();
    } on DioException catch (e) {
      if (!mounted) return;
      final msg = e.response?.data is Map
          ? (e.response!.data as Map)['message']?.toString()
          : null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg ?? e.message ?? e.toString())),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
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

  Widget _cycleFilterChips() {
    final l10n = context.l10n;
    return Wrap(
      spacing: 8,
      children: [
        FilterChip(
          label: Text(l10n.settlementsFilterAll),
          selected: _cycleFilter == null,
          onSelected: (_) {
            setState(() => _cycleFilter = null);
            _load();
          },
        ),
        FilterChip(
          label: Text(l10n.settlementsFilterDaily),
          selected: _cycleFilter == 'daily',
          onSelected: (_) {
            setState(() => _cycleFilter = 'daily');
            _load();
          },
        ),
        FilterChip(
          label: Text(l10n.settlementsFilterWeekly),
          selected: _cycleFilter == 'weekly',
          onSelected: (_) {
            setState(() => _cycleFilter = 'weekly');
            _load();
          },
        ),
      ],
    );
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
                onPressed: () => _create(),
                icon: const Icon(Icons.add),
                label: Text(l10n.recordSettlement),
              ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          child: SegmentedButton<int>(
            segments: [
              ButtonSegment(
                value: 0,
                label: Text(l10n.settlementsDueTab),
                icon: const Icon(Icons.schedule_outlined),
              ),
              ButtonSegment(
                value: _historyTab,
                label: Text(l10n.settlementsHistoryTab),
                icon: const Icon(Icons.history),
              ),
            ],
            selected: {_tabIndex},
            onSelectionChanged: (s) => setState(() => _tabIndex = s.first),
          ),
        ),
        if (_tabIndex == 0)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: _cycleFilterChips(),
          ),
        Expanded(
          child: _loading
              ? const LoadingView()
              : _error != null
                  ? ErrorView(message: _error!, onRetry: _load)
                  : _tabIndex == 0
                      ? _buildDueList(context, canCreate)
                      : _buildHistoryList(context),
        ),
      ],
    );
  }

  Widget _buildDueList(BuildContext context, bool canCreate) {
    final l10n = context.l10n;
    final items = _dueItems ?? const <SettlementUpcomingRow>[];

    return EntityListView(
      itemCount: items.length,
      emptyMessage: l10n.settlementsUpcomingEmpty,
      itemBuilder: (context, i) {
        final row = items[i];
        return EntityListTile(
          title: row.customerName,
          subtitle:
              '${l10n.amountDue}: ${formatMoney(context, row.amountDue)} · ${localizeSettlementCycle(context, row.settlementCycle)}',
          leading: const Icon(Icons.notifications_active_outlined),
          trailing: canCreate
              ? Wrap(
                  spacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    OutlinedButton(
                      onPressed: () => _partialPay(row),
                      child: Text(l10n.partialPay),
                    ),
                    FilledButton(
                      onPressed: () => _create(initialCustomerId: row.customerId),
                      child: Text(l10n.settleAll),
                    ),
                  ],
                )
              : Chip(
                  label: Text(
                    localizeSettlementCycle(context, row.settlementCycle),
                  ),
                  backgroundColor: AppColors.primaryContainer,
                  visualDensity: VisualDensity.compact,
                ),
        );
      },
    );
  }

  Widget _buildHistoryList(BuildContext context) {
    final l10n = context.l10n;
    final items = _historyItems ?? const <Map<String, dynamic>>[];

    return EntityListView(
      itemCount: items.length,
      emptyMessage: l10n.noData,
      itemBuilder: (context, i) {
        final s = items[i];
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
    );
  }
}

class _RecordSettlementDialog extends StatefulWidget {
  const _RecordSettlementDialog({
    required this.customers,
    this.initialCustomerId,
  });

  final List<CustomerModel> customers;
  final String? initialCustomerId;

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
    final initial = widget.initialCustomerId;
    if (initial != null &&
        widget.customers.any((c) => c.id == initial)) {
      _customerId = initial;
      return;
    }
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
