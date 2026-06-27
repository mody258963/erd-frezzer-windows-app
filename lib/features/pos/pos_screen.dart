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
import '../../core/layout/app_breakpoints.dart';
import '../../core/l10n/api_labels.dart';
import '../../core/l10n/l10n_extension.dart';
import '../../core/theme/app_colors.dart';
import '../../core/printer/printer_print_helper.dart';
import '../../core/printer/services/printer_service.dart';
import '../../core/utils/sale_quantity.dart';
import '../../data/local/app_database.dart';
import '../../data/models/branch_model.dart';
import '../../data/repositories/dashboard_repository.dart';
import '../../data/repositories/installment_repository.dart';
import '../../data/repositories/invoice_repository.dart';
import '../../data/repositories/settlement_repository.dart';
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
          final screenSize = MediaQuery.sizeOf(context);
          final posDisplay = AppBreakpoints.isPosDisplay(screenSize);
          final pagePadding = posDisplay ? 8.0 : (screenSize.width < 1024 ? 12.0 : 16.0);
          return PageScaffold(
            title: l10n.posTitle,
            subtitle: posDisplay ? null : l10n.posSubtitle,
            dense: posDisplay,
            scrollable: false,
            actions: [
              if (_catalogSyncing)
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Tooltip(
                    message: l10n.syncing,
                    child: SizedBox(
                      width: posDisplay ? 18 : 22,
                      height: posDisplay ? 18 : 22,
                      child: const CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
              _PrintDaySalesButton(
                branchId: branchId,
                branchName: branchName,
                iconOnly: posDisplay,
              ),
            ],
            padding: EdgeInsets.fromLTRB(
              pagePadding,
              posDisplay ? 8 : 12,
              pagePadding,
              pagePadding,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (canPickBranch) ...[
                  BranchDropdown(
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
                  SizedBox(height: posDisplay ? 6 : 12),
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
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        final compact = AppBreakpoints.isCompact(size);
        final ultraCompact = AppBreakpoints.isPosDisplay(size);
        final partsPanel = _PosPartsPanel(
          search: widget.search,
          searchFocus: widget.searchFocus,
          state: widget.state,
          branchId: widget.branchId,
          ultraCompact: ultraCompact,
        );
        final cartPanel = _PosCartPanel(
          state: widget.state,
          branchId: widget.branchId,
          compact: compact,
          ultraCompact: ultraCompact,
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
                  isScrollable: ultraCompact,
                  tabAlignment: ultraCompact ? TabAlignment.start : TabAlignment.fill,
                  labelStyle: ultraCompact
                      ? Theme.of(context).textTheme.labelMedium
                      : null,
                  tabs: ultraCompact
                      ? [
                          Tab(
                            height: 40,
                            icon: const Icon(Icons.qr_code_scanner, size: 20),
                            text: l10n.searchScanBarcode,
                          ),
                          Tab(
                            height: 40,
                            icon: Badge(
                              isLabelVisible: widget.state.lines.isNotEmpty,
                              label: Text('${widget.state.lines.length}'),
                              child: const Icon(Icons.shopping_cart_outlined,
                                  size: 20),
                            ),
                            text: l10n.cart,
                          ),
                        ]
                      : [
                          Tab(text: l10n.searchScanBarcode),
                          Tab(
                            text: widget.state.lines.isEmpty
                                ? l10n.cart
                                : '${l10n.cart} (${widget.state.lines.length})',
                          ),
                        ],
                ),
                SizedBox(height: ultraCompact ? 4 : 8),
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
    this.ultraCompact = false,
  });

  final TextEditingController search;
  final FocusNode searchFocus;
  final PosState state;
  final String branchId;
  final bool ultraCompact;

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
            labelText: ultraCompact ? null : l10n.searchScanBarcode,
            hintText: ultraCompact ? l10n.searchScanBarcode : null,
            prefixIcon: Icon(
              Icons.qr_code_scanner,
              size: ultraCompact ? 20 : 24,
            ),
            isDense: true,
            contentPadding: ultraCompact
                ? const EdgeInsets.symmetric(horizontal: 10, vertical: 10)
                : null,
          ),
          style: ultraCompact
              ? Theme.of(context).textTheme.bodyMedium
              : null,
          onChanged: (q) => context.read<PosBloc>().add(PosSearch(q)),
        ),
        SizedBox(height: ultraCompact ? 4 : 8),
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
                        visualDensity: ultraCompact
                            ? VisualDensity.compact
                            : VisualDensity.compact,
                        contentPadding: ultraCompact
                            ? const EdgeInsets.symmetric(horizontal: 8)
                            : null,
                        leading: PartNetworkImage(
                          imageUrl: p.imageUrl,
                          width: ultraCompact ? 32 : 40,
                          height: ultraCompact ? 32 : 40,
                        ),
                        title: Text(
                          '${p.code} — ${p.name}',
                          maxLines: ultraCompact ? 1 : 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: ultraCompact ? 12 : 14,
                          ),
                        ),
                        subtitle: Text(
                          '${l10n.price}: ${p.sellPrice}',
                          style: ultraCompact
                              ? Theme.of(context).textTheme.labelSmall
                              : null,
                        ),
                        trailing: Icon(
                          Icons.add_circle_outline,
                          size: ultraCompact ? 20 : 24,
                        ),
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
    this.ultraCompact = false,
  });

  final PosState state;
  final String branchId;
  final bool compact;
  final bool ultraCompact;

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
    final ultraCompact = widget.ultraCompact;
    final saleOptions = _PosSaleOptions(
      state: state,
      ultraCompact: ultraCompact,
    );
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: EdgeInsets.all(ultraCompact ? 6 : (compact ? 8 : 12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!ultraCompact)
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
            if (!ultraCompact) SizedBox(height: compact ? 6 : 8),
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
                        ultraCompact: ultraCompact,
                      ),
                    ),
            ),
            _PosCheckoutFooter(
              state: state,
              branchId: widget.branchId,
              amountPaidCtrl: _amountPaidCtrl,
              compact: compact,
              ultraCompact: ultraCompact,
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
  const _PosSaleOptions({
    required this.state,
    this.ultraCompact = false,
  });

  final PosState state;
  final bool ultraCompact;

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
            contentPadding: ultraCompact
                ? const EdgeInsets.symmetric(horizontal: 10, vertical: 8)
                : null,
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
        SizedBox(height: ultraCompact ? 6 : 8),
        SegmentedButton<String>(
          style: ButtonStyle(
            visualDensity: VisualDensity.compact,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            textStyle: ultraCompact
                ? WidgetStatePropertyAll(
                    Theme.of(context).textTheme.labelSmall,
                  )
                : null,
          ),
          segments: [
            ButtonSegment(
              value: 'cash',
              label: Text(l10n.cash),
              icon: Icon(Icons.payments_outlined,
                  size: ultraCompact ? 14 : 16),
            ),
            ButtonSegment(
              value: 'credit',
              label: Text(l10n.credit),
              icon: Icon(Icons.credit_card, size: ultraCompact ? 14 : 16),
            ),
          ],
          selected: {state.paymentType},
          onSelectionChanged: (s) =>
              context.read<PosBloc>().add(PosSetPayment(s.first)),
        ),
        SizedBox(height: ultraCompact ? 6 : 8),
        TextField(
          decoration: InputDecoration(
            labelText: l10n.discount,
            isDense: true,
            contentPadding: ultraCompact
                ? const EdgeInsets.symmetric(horizontal: 10, vertical: 8)
                : null,
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
    this.ultraCompact = false,
  });

  final PosState state;
  final String branchId;
  final TextEditingController amountPaidCtrl;
  final bool compact;
  final bool ultraCompact;

  double get _gap => ultraCompact ? 3 : (compact ? 4 : 6);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Divider(height: 1),
        SizedBox(height: _gap),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.subtotal,
              style: ultraCompact
                  ? Theme.of(context).textTheme.bodyMedium
                  : null,
            ),
            Text(
              state.subtotal.toStringAsFixed(2),
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontSize: ultraCompact ? 13 : null,
                  ),
            ),
          ],
        ),
        SizedBox(height: _gap),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: ultraCompact ? 8 : 10,
            vertical: ultraCompact ? 4 : (compact ? 6 : 8),
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
                      fontSize: ultraCompact ? 13 : null,
                    ),
              ),
              Text(
                state.total.toStringAsFixed(2),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.onPrimaryContainer,
                      fontWeight: FontWeight.w800,
                      fontSize: ultraCompact ? 15 : null,
                    ),
              ),
            ],
          ),
        ),
        if (state.isCash && state.lines.isNotEmpty) ...[
          SizedBox(height: ultraCompact ? 4 : (compact ? 6 : 8)),
          TextField(
            decoration: InputDecoration(
              labelText: l10n.amountReceived,
              isDense: true,
              suffixText: 'EGP',
              contentPadding: ultraCompact
                  ? const EdgeInsets.symmetric(horizontal: 10, vertical: 8)
                  : null,
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
              margin: EdgeInsets.only(top: ultraCompact ? 4 : (compact ? 6 : 8)),
              padding: EdgeInsets.symmetric(
                horizontal: ultraCompact ? 8 : 10,
                vertical: ultraCompact ? 4 : (compact ? 6 : 8),
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
        SizedBox(height: ultraCompact ? 4 : (compact ? 6 : 10)),
        Row(
          children: [
            ultraCompact
                ? IconButton(
                    tooltip: l10n.clear,
                    onPressed: () =>
                        context.read<PosBloc>().add(const PosClearCart()),
                    icon: const Icon(Icons.clear_all, size: 20),
                  )
                : OutlinedButton(
                    onPressed: () =>
                        context.read<PosBloc>().add(const PosClearCart()),
                    child: Text(l10n.clear),
                  ),
            SizedBox(width: ultraCompact ? 4 : 8),
            Expanded(
              child: FilledButton.icon(
                style: ultraCompact
                    ? FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 10,
                        ),
                        textStyle:
                            Theme.of(context).textTheme.labelLarge,
                      )
                    : null,
                onPressed: state.completing ||
                        state.lines.isEmpty ||
                        !state.canCompleteCash
                    ? null
                    : () => context
                        .read<PosBloc>()
                        .add(PosComplete(branchId)),
                icon: state.completing
                    ? SizedBox(
                        height: ultraCompact ? 14 : 16,
                        width: ultraCompact ? 14 : 16,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.onPrimary,
                        ),
                      )
                    : Icon(
                        Icons.check_circle_outline,
                        size: ultraCompact ? 16 : 18,
                      ),
                label: Text(
                  state.completing ? l10n.processing : l10n.completeSale,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
    this.ultraCompact = false,
  });

  final PosLine line;
  final bool compact;
  final bool ultraCompact;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: ultraCompact ? 2 : 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  '${line.code} — ${line.name}',
                  maxLines: ultraCompact ? 1 : 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: ultraCompact ? 12 : 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                tooltip: l10n.removeFromCart,
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
                constraints: BoxConstraints(
                  minWidth: ultraCompact ? 28 : 32,
                  minHeight: ultraCompact ? 28 : 32,
                ),
                icon: Icon(
                  Icons.delete_outline,
                  size: ultraCompact ? 18 : 20,
                  color: Theme.of(context).colorScheme.error,
                ),
                onPressed: () => context
                    .read<PosBloc>()
                    .add(PosRemoveLine(line.partId)),
              ),
            ],
          ),
          if (!ultraCompact)
            Text(
              '${l10n.available}: ${formatSaleQuantity(line.available, unit: line.unit)}'
              '${line.unit != null && line.unit!.isNotEmpty ? ' ${localizePartUnitLabel(context, line.unit!, line.unit!)}' : ''}',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          SizedBox(height: ultraCompact ? 2 : 4),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: _CartLinePriceField(
                  partId: line.partId,
                  unitPrice: line.unitPrice,
                  label: l10n.price,
                  ultraCompact: ultraCompact,
                ),
              ),
              SizedBox(width: ultraCompact ? 2 : 4),
              IconButton(
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
                constraints: BoxConstraints(
                  minWidth: ultraCompact ? 28 : 32,
                  minHeight: ultraCompact ? 28 : 32,
                ),
                icon: Icon(Icons.remove_circle_outline,
                    size: ultraCompact ? 18 : 20),
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
                  ultraCompact: ultraCompact,
                ),
              ),
              IconButton(
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
                constraints: BoxConstraints(
                  minWidth: ultraCompact ? 28 : 32,
                  minHeight: ultraCompact ? 28 : 32,
                ),
                icon: Icon(Icons.add_circle_outline,
                    size: ultraCompact ? 18 : 20),
                onPressed: () => context.read<PosBloc>().add(
                      PosUpdateQty(
                        line.partId,
                        line.quantity + saleQuantityStep(line.unit),
                      ),
                    ),
              ),
              SizedBox(width: ultraCompact ? 2 : 4),
              Text(
                line.lineTotal.toStringAsFixed(2),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: ultraCompact ? 12 : null,
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
    this.ultraCompact = false,
  });

  final String partId;
  final double unitPrice;
  final String label;
  final bool ultraCompact;

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
      style: TextStyle(fontSize: widget.ultraCompact ? 12 : 13),
      decoration: InputDecoration(
        isDense: true,
        labelText: widget.label,
        contentPadding: EdgeInsets.symmetric(
          horizontal: widget.ultraCompact ? 6 : 8,
          vertical: widget.ultraCompact ? 6 : 8,
        ),
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
    this.ultraCompact = false,
  });

  final String partId;
  final double quantity;
  final String? unit;
  final bool ultraCompact;

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
      style: TextStyle(
        fontSize: widget.ultraCompact ? 12 : 13,
        fontWeight: FontWeight.w700,
      ),
      decoration: InputDecoration(
        isDense: true,
        labelText: l10n.quantity,
        suffixText: unitLabel,
        contentPadding: EdgeInsets.symmetric(
          horizontal: widget.ultraCompact ? 4 : 6,
          vertical: widget.ultraCompact ? 6 : 8,
        ),
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
    this.iconOnly = false,
  });

  final String branchId;
  final String? branchName;
  final bool iconOnly;

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
      final report = await loadDailyDrawerReport(
        invoiceRepository: getIt<InvoiceRepository>(),
        database: getIt<AppDatabase>(),
        connectivity: getIt<ConnectivityCubit>(),
        dashboardRepository: getIt<DashboardRepository>(),
        settlementRepository: getIt<SettlementRepository>(),
        installmentRepository: getIt<InstallmentRepository>(),
        branchId: widget.branchId,
        branchName: widget.branchName,
      );
      if (!mounted) return;
      if (report.cashSalesTotal <= 0 &&
          report.collections.isEmpty &&
          report.drawerTotal == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.noDaySales)),
        );
        return;
      }
      await printDailyDrawerReport(report);
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
    if (widget.iconOnly) {
      return IconButton.filledTonal(
        tooltip: l10n.printDaySales,
        onPressed: _printing ? null : _print,
        icon: _printing
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.print_outlined, size: 20),
      );
    }
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
