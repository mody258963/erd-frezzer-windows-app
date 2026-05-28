import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_cubit.dart';
import '../../core/auth/role_permissions.dart';
import '../../core/l10n/api_labels.dart';
import '../../core/l10n/l10n_extension.dart';
import '../../data/models/invoice_model.dart';
import '../../data/models/user_role.dart';
import '../../data/repositories/invoice_repository.dart';
import '../../di/injection.dart';
import '../shared/entity_list_tile.dart';
import '../shared/loading_error.dart';
import '../shared/page_header.dart';

class InvoicesScreen extends StatefulWidget {
  const InvoicesScreen({super.key});

  @override
  State<InvoicesScreen> createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends State<InvoicesScreen> {
  List<InvoiceModel>? _items;
  String? _error;
  bool _loading = true;
  bool _pendingCredit = false;

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
      final repo = getIt<InvoiceRepository>();
      final items = _pendingCredit
          ? await repo.pendingCredit()
          : await repo.list();
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
    final role = context.read<AuthCubit>().state.user?.role ?? UserRole.manager;
    final canCancel = RolePermissions.canPerform(AppAction.invoiceCancel, role);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHeader(
          title: l10n.invoicesTitle,
          actions: [
            FilterChip(
              label: Text(l10n.pendingCredit),
              selected: _pendingCredit,
              onSelected: (v) {
                setState(() => _pendingCredit = v);
                _load();
              },
            ),
            IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
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
                        final inv = _items![i];
                        return EntityListTile(
                          title:
                              '${inv.customerName ?? inv.customerId} — ${formatMoney(context, inv.total)}',
                          subtitle: l10n.invoiceRowSubtitle(
                            localizePaymentType(context, inv.paymentType),
                            inv.createdAt ?? '',
                          ),
                          leading: const Icon(Icons.receipt_outlined),
                          onTap: () => context.push('/invoices/${inv.id}'),
                          trailing: canCancel
                              ? IconButton(
                                  tooltip: l10n.delete,
                                  icon: const Icon(Icons.cancel_outlined),
                                  onPressed: () async {
                                    await getIt<InvoiceRepository>().cancel(inv.id);
                                    await _load();
                                  },
                                )
                              : null,
                        );
                      },
                    ),
        ),
      ],
    );
  }
}

class InvoiceDetailScreen extends StatefulWidget {
  const InvoiceDetailScreen({required this.id, super.key});
  final String id;

  @override
  State<InvoiceDetailScreen> createState() => _InvoiceDetailScreenState();
}

class _InvoiceDetailScreenState extends State<InvoiceDetailScreen> {
  InvoiceModel? _invoice;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final inv = await getIt<InvoiceRepository>().get(widget.id);
      setState(() {
        _invoice = inv;
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

    if (_loading) return const Scaffold(body: LoadingView());
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.invoicesTitle)),
        body: ErrorView(message: _error!, onRetry: _load),
      );
    }
    final inv = _invoice!;
    final shortId =
        inv.id.length > 8 ? inv.id.substring(0, 8) : inv.id;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.invoiceDetailTitle(shortId))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          EntityListTile(
            title: l10n.totalValue(formatMoney(context, inv.total)),
            subtitle: l10n.paymentValue(
              localizePaymentType(context, inv.paymentType),
            ),
            leading: const Icon(Icons.summarize_outlined),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.items,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          ...inv.items.map(
            (i) => EntityListTile(
              title: i.partCode ?? i.partId,
              trailing: Text(l10n.quantityTimes('${i.quantity}')),
              leading: const Icon(Icons.build_outlined),
            ),
          ),
        ],
      ),
    );
  }
}
