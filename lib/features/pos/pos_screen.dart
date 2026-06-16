import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';

import '../../core/auth/auth_cubit.dart';
import '../../core/branch/branch_filter_cubit.dart';
import '../../core/events/app_refresh_bus.dart';
import '../../core/connectivity/connectivity_cubit.dart';
import '../../core/settings/settings_service.dart';
import '../../data/repositories/catalog_sync_repository.dart';
import '../../core/l10n/api_labels.dart';
import '../../core/l10n/l10n_extension.dart';
import '../../core/theme/app_colors.dart';
import '../../core/printer/printer_print_helper.dart';
import '../../core/printer/services/printer_service.dart';
import '../../core/utils/sale_quantity.dart';
import '../../data/local/app_database.dart';
import '../../data/models/branch_model.dart';
import '../../data/repositories/invoice_repository.dart';
import '../../di/injection.dart';
import '../shared/branch_dropdown.dart';
import '../shared/page_scaffold.dart';
import '../shared/part_network_image.dart';
import 'daily_sales_report_loader.dart';
import 'pos_bloc.dart';

String _receiptCashQuery(PosState state) {
  final paid = state.lastAmountPaid;
  if (paid == null) return '';
  final change = (state.lastChange ?? 0).toStringAsFixed(2);
  return '&paid=${paid.toStringAsFixed(2)}&change=$change';
}

class PosScreen extends StatefulWidget {
  const PosScreen({super.key});

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  static final _log = Logger('PosScreen');

  final _searchFocus = FocusNode();
  final _search = TextEditingController();

  String? _posBranchId;
  List<BranchModel> _branches = [];
  bool _catalogSyncing = false;

  Future<void> _syncPosCatalogBackground(String branchId) async {
    if (!getIt<ConnectivityCubit>().state.isOnline) return;
    if (!mounted) return;
    setState(() => _catalogSyncing = true);
    try {
      await getIt<CatalogSyncRepository>().refresh(branchId);
    } catch (_) {}
    if (mounted) setState(() => _catalogSyncing = false);
  }

  Future<void> _refreshStockAfterSale(String branchId) async {
    if (!getIt<ConnectivityCubit>().state.isOnline) return;
    try {
      await getIt<CatalogSyncRepository>().refreshStockOnly(branchId);
    } catch (_) {}
  }

  void _reloadPosFromCache({PosBloc? bloc, bool silent = true}) {
    try {
      final b = bloc ?? context.read<PosBloc>();
      b.add(PosLoad(silent: silent));
      final branchId = _posBranchId;
      if (branchId != null && branchId.isNotEmpty) {
        b.add(PosRefreshStock(branchId));
      }
    } catch (_) {}
  }

  void _onCatalogRefresh(AppRefreshKind kind) {
    if (!mounted) return;
    if (kind == AppRefreshKind.branchFilter) {
      _resolveBranch();
      return;
    }
    if (kind != AppRefreshKind.catalog) return;
    _reloadPosFromCache();
  }

  void _bootstrapBranchFromCache() {
    final user = context.read<AuthCubit>().state.user;
    if (user == null) return;
    if (!user.canSelectBranch &&
        user.branchId != null &&
        user.branchId!.isNotEmpty) {
      setState(() => _posBranchId = user.branchId);
      return;
    }
    if (user.canSelectBranch) {
      final id = context.read<BranchFilterCubit>().state.selectedBranchId ??
          getIt<SettingsService>().posBranchId ??
          user.branchId;
      if (id != null && id.isNotEmpty) {
        setState(() => _posBranchId = id);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    getIt<AppRefreshBus>().addListener(_onCatalogRefresh);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _bootstrapBranchFromCache();
      _searchFocus.requestFocus();
      _resolveBranch();
    });
  }

  Future<void> _resolveBranch() async {
    final user = context.read<AuthCubit>().state.user;
    if (user == null) return;

    if (user.canSelectBranch) {
      try {
        final branches = await loadActiveBranches(
          allowedIds: user.accessibleBranchIds,
        );
        var id = context.read<BranchFilterCubit>().state.selectedBranchId ??
            getIt<SettingsService>().posBranchId ??
            user.branchId;
        if (id != null && !branches.any((b) => b.id == id)) {
          id = branches.isNotEmpty ? branches.first.id : null;
        }
        id ??= branches.length == 1 ? branches.first.id : null;
        if (!mounted) return;
        setState(() {
          _branches = branches;
          _posBranchId ??= id;
        });
        if (id != null) {
          await getIt<SettingsService>().setPosBranchId(id);
          if (_posBranchId == id) {
            unawaited(_syncPosCatalogBackground(id));
          }
        }
      } catch (_) {}
      return;
    }

    if (user.branchId != null && user.branchId!.isNotEmpty) {
      if (!mounted) return;
      setState(() => _posBranchId ??= user.branchId);
      unawaited(_syncPosCatalogBackground(user.branchId!));
    }
  }

  @override
  void dispose() {
    getIt<AppRefreshBus>().removeListener(_onCatalogRefresh);
    _search.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final user = context.read<AuthCubit>().state.user;
    final branchId = _posBranchId;

    if (user != null &&
        !user.canSelectBranch &&
        (branchId == null || branchId.isEmpty)) {
      _log.warning(
        'POS blocked: no branchId for user=${user.id} '
        'branchName=${user.branchName} email=${user.email}',
      );
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.branchRequired, textAlign: TextAlign.center),
              if (user.branchName != null) ...[
                const SizedBox(height: 8),
                Text(
                  '${l10n.branch}: ${user.branchName}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () async {
                  await context.read<AuthCubit>().loadSession();
                  if (mounted) await _resolveBranch();
                },
                icon: const Icon(Icons.refresh),
                label: Text(l10n.tryAgain),
              ),
            ],
          ),
        ),
      );
    }

    if (user != null &&
        user.canSelectBranch &&
        (branchId == null || branchId.isEmpty)) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.posSelectBranch,
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.posBranchRequiredHint,
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                if (_branches.isEmpty)
                  const CircularProgressIndicator()
                else
                  BranchDropdown(
                    branches: _branches,
                    value: branchId,
                    label: l10n.branch,
                    onChanged: (v) async {
                      if (v == null) return;
                      await getIt<SettingsService>().setPosBranchId(v);
                      if (!mounted) return;
                      setState(() => _posBranchId = v);
                      unawaited(_syncPosCatalogBackground(v));
                    },
                  ),
              ],
            ),
          ),
        ),
      );
    }

    if (branchId == null || branchId.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    _log.fine('POS open branchId=$branchId branchName=${user?.branchName}');

    return BlocProvider(
      key: ValueKey(branchId),
      create: (_) => PosBloc(
        getIt<AppDatabase>(),
        getIt<InvoiceRepository>(),
        getIt<ConnectivityCubit>(),
        getIt<SettingsService>(),
      )..add(const PosLoad()),
      child: BlocConsumer<PosBloc, PosState>(
        listenWhen: (previous, current) =>
            (current.lastLocalId != null &&
                previous.lastLocalId != current.lastLocalId) ||
            (current.lastServerId != null &&
                previous.lastServerId != current.lastServerId),
        listener: (context, state) {
          final bloc = context.read<PosBloc>();
          if (state.lastServerId != null) {
            getIt<AppRefreshBus>().notify(AppRefreshKind.dashboard);
            getIt<AppRefreshBus>().notify(AppRefreshKind.invoices);
            getIt<AppRefreshBus>().notify(AppRefreshKind.inventory);
            unawaited(_refreshStockAfterSale(branchId));
          }
          if (state.lastLocalId != null) {
            getIt<AppRefreshBus>().notify(AppRefreshKind.inventory);
            final cashQ = _receiptCashQuery(state);
            context
                .push('/pos/receipt/${state.lastLocalId}?offline=1$cashQ')
                .then((_) {
              if (context.mounted) {
                bloc.add(const PosAcknowledgeSale());
              }
            });
          } else if (state.lastServerId != null) {
            final cashQ = _receiptCashQuery(state);
            final sep = cashQ.isEmpty ? '' : '?${cashQ.substring(1)}';
            context.push('/pos/receipt/${state.lastServerId}$sep').then((_) {
              if (context.mounted) {
                bloc.add(const PosAcknowledgeSale());
              }
            });
          }
        },
        builder: (context, state) {
          final canPickBranch = user?.canSelectBranch == true && _branches.length > 1;
          String? branchName = user?.branchName;
          for (final b in _branches) {
            if (b.id == branchId) {
              branchName = b.name;
              break;
            }
          }
          return PageScaffold(
            title: l10n.posTitle,
            subtitle: l10n.posSubtitle,
            scrollable: false,
            actions: [
              if (_catalogSyncing)
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Tooltip(
                    message: l10n.syncing,
                    child: const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
              _PrintDaySalesButton(
                branchId: branchId,
                branchName: branchName,
              ),
            ],
            padding: EdgeInsets.fromLTRB(
              16,
              12,
              16,
              MediaQuery.sizeOf(context).width < 1024 ? 12 : 24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (canPickBranch) ...[
                  SizedBox(
                    width: 320,
                    child: BranchDropdown(
                      branches: _branches,
                      value: branchId,
                      label: l10n.branch,
                      onChanged: (v) async {
                        if (v == null) return;
                        await getIt<SettingsService>().setPosBranchId(v);
                        if (!context.mounted) return;
                        setState(() => _posBranchId = v);
                        unawaited(_syncPosCatalogBackground(v));
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                Expanded(
                  child: _PosLayout(
                    search: _search,
                    searchFocus: _searchFocus,
                    state: state,
                    branchId: branchId,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PosLayout extends StatefulWidget {
  const _PosLayout({
    required this.search,
    required this.searchFocus,
    required this.state,
    required this.branchId,
  });

  final TextEditingController search;
  final FocusNode searchFocus;
  final PosState state;
  final String branchId;

  @override
  State<_PosLayout> createState() => _PosLayoutState();
}

class _PosLayoutState extends State<_PosLayout>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 1024 ||
            constraints.maxHeight < 720;
        final partsPanel = _PosPartsPanel(
          search: widget.search,
          searchFocus: widget.searchFocus,
          state: widget.state,
          branchId: widget.branchId,
        );
        final cartPanel = _PosCartPanel(
          state: widget.state,
          branchId: widget.branchId,
          compact: compact,
        );

        if (compact) {
          return BlocListener<PosBloc, PosState>(
            listenWhen: (previous, current) =>
                current.lines.length > previous.lines.length,
            listener: (_, __) {
              if (_tabController.index != 1) {
                _tabController.animateTo(1);
              }
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TabBar(
                  controller: _tabController,
                  tabs: [
                    Tab(text: l10n.searchScanBarcode),
                    Tab(
                      text: widget.state.lines.isEmpty
                          ? l10n.cart
                          : '${l10n.cart} (${widget.state.lines.length})',
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      partsPanel,
                      cartPanel,
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(flex: 3, child: partsPanel),
            const SizedBox(width: 16),
            Expanded(flex: 2, child: cartPanel),
          ],
        );
      },
    );
  }
}

class _PosPartsPanel extends StatelessWidget {
  const _PosPartsPanel({
    required this.search,
    required this.searchFocus,
    required this.state,
    required this.branchId,
  });

  final TextEditingController search;
  final FocusNode searchFocus;
  final PosState state;
  final String branchId;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: search,
          focusNode: searchFocus,
          decoration: InputDecoration(
            labelText: l10n.searchScanBarcode,
            prefixIcon: const Icon(Icons.qr_code_scanner),
            isDense: true,
          ),
          onChanged: (q) => context.read<PosBloc>().add(PosSearch(q)),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Card(
            margin: EdgeInsets.zero,
            child: state.searchResults.isEmpty
                ? Center(
                    child: Text(
                      l10n.searchPartToAdd,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                    ),
                  )
                : ListView.separated(
                    itemCount: state.searchResults.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final p = state.searchResults[i];
                      return ListTile(
                        dense: true,
                        visualDensity: VisualDensity.compact,
                        leading: PartNetworkImage(
                          imageUrl: p.imageUrl,
                          width: 40,
                          height: 40,
                        ),
                        title: Text(
                          '${p.code} — ${p.name}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        subtitle: Text('${l10n.price}: ${p.sellPrice}'),
                        trailing: const Icon(Icons.add_circle_outline),
                        onTap: () {
                          context.read<PosBloc>().add(PosAddLine(p, branchId));
                          search.clear();
                          context.read<PosBloc>().add(const PosSearch(''));
                        },
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }
}

class _PosCartPanel extends StatefulWidget {
  const _PosCartPanel({
    required this.state,
    required this.branchId,
    this.compact = false,
  });

  final PosState state;
  final String branchId;
  final bool compact;

  @override
  State<_PosCartPanel> createState() => _PosCartPanelState();
}

class _PosCartPanelState extends State<_PosCartPanel> {
  late final TextEditingController _amountPaidCtrl;

  PosState get state => widget.state;

  @override
  void initState() {
    super.initState();
    _amountPaidCtrl = TextEditingController(
      text: _formatPaid(state.amountPaid),
    );
  }

  @override
  void didUpdateWidget(covariant _PosCartPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newText = _formatPaid(state.amountPaid);
    if (_amountPaidCtrl.text != newText &&
        double.tryParse(_amountPaidCtrl.text.replaceAll(',', '')) !=
            state.amountPaid) {
      _amountPaidCtrl.text = newText;
    }
  }

  @override
  void dispose() {
    _amountPaidCtrl.dispose();
    super.dispose();
  }

  String _formatPaid(double v) => v > 0 ? v.toStringAsFixed(2) : '';

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final compact = widget.compact;
    final saleOptions = _PosSaleOptions(state: state);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: EdgeInsets.all(compact ? 8 : 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.cart,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                if (state.lines.isNotEmpty)
                  Text(
                    '${state.lines.length}',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
              ],
            ),
            SizedBox(height: compact ? 6 : 8),
            if (compact)
              Theme(
                data: Theme.of(context)
                    .copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  childrenPadding: const EdgeInsets.only(bottom: 4),
                  title: Text(
                    _saleOptionsSummary(context, state),
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  initiallyExpanded: state.lines.isEmpty,
                  children: [saleOptions],
                ),
              )
            else ...[
              saleOptions,
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Divider(height: 1),
              ),
            ],
            Expanded(
              child: state.lines.isEmpty
                  ? Center(
                      child: Text(
                        l10n.cartEmpty,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                    )
                  : ListView.separated(
                      itemCount: state.lines.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, i) => _CartLineTile(
                        line: state.lines[i],
                        compact: compact,
                      ),
                    ),
            ),
            _PosCheckoutFooter(
              state: state,
              branchId: widget.branchId,
              amountPaidCtrl: _amountPaidCtrl,
              compact: compact,
            ),
          ],
        ),
      ),
    );
  }

  String _saleOptionsSummary(BuildContext context, PosState state) {
    final l10n = context.l10n;
    String? customerName;
    if (state.customerId != null) {
      for (final c in state.customers) {
        if (c.id == state.customerId) {
          customerName = c.name;
          break;
        }
      }
    }
    final payment =
        state.paymentType == 'credit' ? l10n.credit : l10n.cash;
    final parts = <String>[
      customerName ?? l10n.customer,
      payment,
      if (state.discount > 0)
        '${l10n.discount}: ${state.discount.toStringAsFixed(2)}',
    ];
    return parts.join(' · ');
  }
}

class _PosSaleOptions extends StatelessWidget {
  const _PosSaleOptions({required this.state});

  final PosState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<String>(
          isExpanded: true,
          value: state.customerId != null &&
                  state.customers.any((c) => c.id == state.customerId)
              ? state.customerId
              : null,
          decoration: InputDecoration(
            labelText: l10n.customer,
            isDense: true,
          ),
          items: state.customers
              .map(
                (c) => DropdownMenuItem(
                  value: c.id,
                  child: Text(c.name, overflow: TextOverflow.ellipsis),
                ),
              )
              .toList(),
          onChanged: (v) => context.read<PosBloc>().add(PosSetCustomer(v)),
        ),
        const SizedBox(height: 8),
        SegmentedButton<String>(
          style: const ButtonStyle(
            visualDensity: VisualDensity.compact,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          segments: [
            ButtonSegment(
              value: 'cash',
              label: Text(l10n.cash),
              icon: const Icon(Icons.payments_outlined, size: 16),
            ),
            ButtonSegment(
              value: 'credit',
              label: Text(l10n.credit),
              icon: const Icon(Icons.credit_card, size: 16),
            ),
          ],
          selected: {state.paymentType},
          onSelectionChanged: (s) =>
              context.read<PosBloc>().add(PosSetPayment(s.first)),
        ),
        const SizedBox(height: 8),
        TextField(
          decoration: InputDecoration(
            labelText: l10n.discount,
            isDense: true,
          ),
          keyboardType: TextInputType.number,
          onChanged: (v) => context.read<PosBloc>().add(
                PosSetDiscount(double.tryParse(v) ?? 0),
              ),
        ),
      ],
    );
  }
}

class _PosCheckoutFooter extends StatelessWidget {
  const _PosCheckoutFooter({
    required this.state,
    required this.branchId,
    required this.amountPaidCtrl,
    this.compact = false,
  });

  final PosState state;
  final String branchId;
  final TextEditingController amountPaidCtrl;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Divider(height: 1),
        SizedBox(height: compact ? 4 : 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(l10n.subtotal),
            Text(
              state.subtotal.toStringAsFixed(2),
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ],
        ),
        SizedBox(height: compact ? 4 : 6),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: 10,
            vertical: compact ? 6 : 8,
          ),
          decoration: BoxDecoration(
            color: AppColors.primaryContainer,
            borderRadius: BorderRadius.circular(AppColors.inputRadius),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.total,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppColors.onPrimaryContainer,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              Text(
                state.total.toStringAsFixed(2),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.onPrimaryContainer,
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ],
          ),
        ),
        if (state.isCash && state.lines.isNotEmpty) ...[
          SizedBox(height: compact ? 6 : 8),
          TextField(
            decoration: InputDecoration(
              labelText: l10n.amountReceived,
              isDense: true,
              suffixText: 'EGP',
            ),
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
            ),
            controller: amountPaidCtrl,
            onChanged: (v) => context.read<PosBloc>().add(
                  PosSetAmountPaid(
                    double.tryParse(v.replaceAll(',', '')) ?? 0,
                  ),
                ),
          ),
          if (state.amountPaid >= state.total && state.total > 0)
            Container(
              margin: EdgeInsets.only(top: compact ? 6 : 8),
              padding: EdgeInsets.symmetric(
                horizontal: 10,
                vertical: compact ? 6 : 8,
              ),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppColors.inputRadius),
                border: Border.all(
                  color: AppColors.success.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.changeDue,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  Text(
                    state.change.toStringAsFixed(2),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ],
              ),
            ),
          if (state.amountPaid > 0 && state.amountPaid < state.total)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                l10n.amountReceivedTooLow,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 12,
                ),
              ),
            ),
        ],
        if (state.error != null) ...[
          const SizedBox(height: 6),
          Text(
            localizePosError(context, state.error),
            style: TextStyle(
              color: Theme.of(context).colorScheme.error,
              fontSize: 12,
            ),
          ),
        ],
        SizedBox(height: compact ? 6 : 10),
        Row(
          children: [
            OutlinedButton(
              onPressed: () =>
                  context.read<PosBloc>().add(const PosClearCart()),
              child: Text(l10n.clear),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton.icon(
                onPressed: state.completing ||
                        state.lines.isEmpty ||
                        !state.canCompleteCash
                    ? null
                    : () => context
                        .read<PosBloc>()
                        .add(PosComplete(branchId)),
                icon: state.completing
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.onPrimary,
                        ),
                      )
                    : const Icon(Icons.check_circle_outline, size: 18),
                label: Text(
                  state.completing ? l10n.processing : l10n.completeSale,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _CartLineTile extends StatelessWidget {
  const _CartLineTile({
    required this.line,
    this.compact = false,
  });

  final PosLine line;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  '${line.code} — ${line.name}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                tooltip: l10n.removeFromCart,
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                icon: Icon(
                  Icons.delete_outline,
                  size: 20,
                  color: Theme.of(context).colorScheme.error,
                ),
                onPressed: () => context
                    .read<PosBloc>()
                    .add(PosRemoveLine(line.partId)),
              ),
            ],
          ),
          Text(
            '${l10n.available}: ${formatSaleQuantity(line.available, unit: line.unit)}'
            '${line.unit != null && line.unit!.isNotEmpty ? ' ${localizePartUnitLabel(context, line.unit!, line.unit!)}' : ''}',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: _CartLinePriceField(
                  partId: line.partId,
                  unitPrice: line.unitPrice,
                  label: l10n.price,
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                icon: const Icon(Icons.remove_circle_outline, size: 20),
                onPressed: () => context.read<PosBloc>().add(
                      PosUpdateQty(
                        line.partId,
                        line.quantity - saleQuantityStep(line.unit),
                      ),
                    ),
              ),
              Expanded(
                flex: 2,
                child: _CartLineQtyField(
                  partId: line.partId,
                  quantity: line.quantity,
                  unit: line.unit,
                ),
              ),
              IconButton(
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                icon: const Icon(Icons.add_circle_outline, size: 20),
                onPressed: () => context.read<PosBloc>().add(
                      PosUpdateQty(
                        line.partId,
                        line.quantity + saleQuantityStep(line.unit),
                      ),
                    ),
              ),
              const SizedBox(width: 4),
              Text(
                line.lineTotal.toStringAsFixed(2),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CartLinePriceField extends StatefulWidget {
  const _CartLinePriceField({
    required this.partId,
    required this.unitPrice,
    required this.label,
  });

  final String partId;
  final double unitPrice;
  final String label;

  @override
  State<_CartLinePriceField> createState() => _CartLinePriceFieldState();
}

class _CartLinePriceFieldState extends State<_CartLinePriceField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.unitPrice.toStringAsFixed(2),
    );
  }

  @override
  void didUpdateWidget(_CartLinePriceField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.unitPrice != widget.unitPrice &&
        double.tryParse(_controller.text) != widget.unitPrice) {
      _controller.text = widget.unitPrice.toStringAsFixed(2);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _commit() {
    final price = double.tryParse(_controller.text.trim());
    if (price != null && price > 0) {
      context.read<PosBloc>().add(PosSetUnitPrice(widget.partId, price));
    } else {
      _controller.text = widget.unitPrice.toStringAsFixed(2);
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _controller,
      textDirection: TextDirection.ltr,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        isDense: true,
        labelText: widget.label,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      ),
      onFieldSubmitted: (_) => _commit(),
      onEditingComplete: _commit,
      onTapOutside: (_) => _commit(),
    );
  }
}

class _CartLineQtyField extends StatefulWidget {
  const _CartLineQtyField({
    required this.partId,
    required this.quantity,
    this.unit,
  });

  final String partId;
  final double quantity;
  final String? unit;

  @override
  State<_CartLineQtyField> createState() => _CartLineQtyFieldState();
}

class _CartLineQtyFieldState extends State<_CartLineQtyField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: formatSaleQuantity(widget.quantity, unit: widget.unit),
    );
  }

  @override
  void didUpdateWidget(covariant _CartLineQtyField oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newText = formatSaleQuantity(widget.quantity, unit: widget.unit);
    if (_controller.text != newText &&
        normalizeSaleQuantity(
              double.tryParse(_controller.text.replaceAll(',', '')) ?? 0,
              widget.unit,
            ) !=
            widget.quantity) {
      _controller.text = newText;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _commit() {
    final parsed = double.tryParse(_controller.text.trim().replaceAll(',', ''));
    if (parsed != null && parsed > 0) {
      context.read<PosBloc>().add(PosUpdateQty(widget.partId, parsed));
    } else {
      _controller.text =
          formatSaleQuantity(widget.quantity, unit: widget.unit);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final unitLabel = widget.unit != null && widget.unit!.isNotEmpty
        ? localizePartUnitLabel(context, widget.unit!, widget.unit!)
        : null;
    return TextFormField(
      controller: _controller,
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
      keyboardType: TextInputType.numberWithOptions(
        decimal: isFractionalSaleUnit(widget.unit),
      ),
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
      decoration: InputDecoration(
        isDense: true,
        labelText: l10n.quantity,
        suffixText: unitLabel,
        contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      ),
      onFieldSubmitted: (_) => _commit(),
      onEditingComplete: _commit,
      onTapOutside: (_) => _commit(),
    );
  }
}

class _PrintDaySalesButton extends StatefulWidget {
  const _PrintDaySalesButton({
    required this.branchId,
    this.branchName,
  });

  final String branchId;
  final String? branchName;

  @override
  State<_PrintDaySalesButton> createState() => _PrintDaySalesButtonState();
}

class _PrintDaySalesButtonState extends State<_PrintDaySalesButton> {
  bool _printing = false;

  Future<void> _print() async {
    if (_printing) return;
    final l10n = context.l10n;
    setState(() => _printing = true);
    try {
      final report = await loadDailySalesReport(
        invoiceRepository: getIt<InvoiceRepository>(),
        database: getIt<AppDatabase>(),
        connectivity: getIt<ConnectivityCubit>(),
        branchId: widget.branchId,
        branchName: widget.branchName,
      );
      if (!mounted) return;
      if (report.lines.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.noDaySales)),
        );
        return;
      }
      await printDailySalesReport(report);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.daySalesPrinted),
          backgroundColor: Colors.green.shade700,
        ),
      );
    } on PrinterException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.printFailed(e.message))),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.printFailed(e.toString()))),
      );
    } finally {
      if (mounted) setState(() => _printing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return FilledButton.tonalIcon(
      onPressed: _printing ? null : _print,
      icon: _printing
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.print_outlined, size: 18),
      label: Text(l10n.printDaySales),
    );
  }
}
