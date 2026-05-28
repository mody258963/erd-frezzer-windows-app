import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';

import '../../core/auth/auth_cubit.dart';
import '../../core/connectivity/connectivity_cubit.dart';
import '../../core/settings/settings_service.dart';
import '../../core/l10n/api_labels.dart';
import '../../core/l10n/l10n_extension.dart';
import '../../core/theme/app_colors.dart';
import '../../data/local/app_database.dart';
import '../../data/repositories/invoice_repository.dart';
import '../../di/injection.dart';
import '../shared/page_scaffold.dart';
import '../shared/part_network_image.dart';
import 'pos_bloc.dart';

class PosScreen extends StatefulWidget {
  const PosScreen({super.key});

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  static final _log = Logger('PosScreen');

  final _searchFocus = FocusNode();
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _search.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthCubit>().state.user;
    final branchId = user?.branchId;
    if (branchId == null || branchId.isEmpty) {
      _log.warning(
        'POS blocked: no branchId for user=${user?.id} '
        'branchName=${user?.branchName} email=${user?.email}',
      );
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                context.l10n.branchRequired,
                textAlign: TextAlign.center,
              ),
              if (user?.branchName != null) ...[
                const SizedBox(height: 8),
                Text(
                  '${context.l10n.branch}: ${user!.branchName}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () async {
                  await context.read<AuthCubit>().loadSession();
                  if (mounted) setState(() {});
                },
                icon: const Icon(Icons.refresh),
                label: Text(context.l10n.tryAgain),
              ),
            ],
          ),
        ),
      );
    }
    _log.fine('POS open branchId=$branchId branchName=${user?.branchName}');

    return BlocProvider(
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
          if (state.lastLocalId != null) {
            context
                .push('/pos/receipt/${state.lastLocalId}?offline=1')
                .then((_) {
              if (context.mounted) {
                bloc.add(const PosAcknowledgeSale());
              }
            });
          } else if (state.lastServerId != null) {
            context.push('/pos/receipt/${state.lastServerId}').then((_) {
              if (context.mounted) {
                bloc.add(const PosAcknowledgeSale());
              }
            });
          }
        },
        builder: (context, state) {
          final l10n = context.l10n;
          return PageScaffold(
            title: l10n.posTitle,
            subtitle: l10n.posSubtitle,
            scrollable: false,
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: _search,
                        focusNode: _searchFocus,
                        decoration: InputDecoration(
                          labelText: l10n.searchScanBarcode,
                          prefixIcon: const Icon(Icons.qr_code_scanner),
                        ),
                        onChanged: (q) =>
                            context.read<PosBloc>().add(PosSearch(q)),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: Card(
                          child: state.searchResults.isEmpty
                              ? Center(
                                  child: Text(
                                    l10n.searchPartToAdd,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant,
                                        ),
                                  ),
                                )
                              : ListView.separated(
                                  itemCount: state.searchResults.length,
                                  separatorBuilder: (_, __) =>
                                      const Divider(height: 1),
                                  itemBuilder: (context, i) {
                                    final p = state.searchResults[i];
                                    return Material(
                                      color: Colors.transparent,
                                      child: ListTile(
                                        leading: PartNetworkImage(
                                          imageUrl: p.imageUrl,
                                          width: 48,
                                          height: 48,
                                        ),
                                        title: Text(
                                          '${p.code} — ${p.name}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        subtitle: Text(
                                          '${l10n.price}: ${p.sellPrice}',
                                          style: TextStyle(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .secondary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        trailing: const Icon(
                                          Icons.add_circle_outline,
                                        ),
                                        onTap: () {
                                          context
                                              .read<PosBloc>()
                                              .add(PosAddLine(p, branchId));
                                          _search.clear();
                                          context
                                              .read<PosBloc>()
                                              .add(const PosSearch(''));
                                        },
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  flex: 2,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            l10n.cart,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            value: state.customerId,
                            decoration: InputDecoration(
                              labelText: l10n.customer,
                            ),
                            items: state.customers
                                .map(
                                  (c) => DropdownMenuItem(
                                    value: c.id,
                                    child: Text(c.name),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) => context
                                .read<PosBloc>()
                                .add(PosSetCustomer(v)),
                          ),
                          const SizedBox(height: 12),
                          SegmentedButton<String>(
                            segments: [
                              ButtonSegment(
                                value: 'cash',
                                label: Text(l10n.cash),
                                icon: const Icon(Icons.payments_outlined, size: 18),
                              ),
                              ButtonSegment(
                                value: 'credit',
                                label: Text(l10n.credit),
                                icon: const Icon(Icons.credit_card, size: 18),
                              ),
                            ],
                            selected: {state.paymentType},
                            onSelectionChanged: (s) => context
                                .read<PosBloc>()
                                .add(PosSetPayment(s.first)),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            decoration: InputDecoration(
                              labelText: l10n.discount,
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (v) => context.read<PosBloc>().add(
                                  PosSetDiscount(double.tryParse(v) ?? 0),
                                ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Divider(),
                          ),
                          Expanded(
                            child: state.lines.isEmpty
                                ? Center(
                                    child: Text(
                                      l10n.cartEmpty,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurfaceVariant,
                                          ),
                                    ),
                                  )
                                : ListView.separated(
                                    itemCount: state.lines.length,
                                    separatorBuilder: (_, __) =>
                                        const Divider(height: 1),
                                    itemBuilder: (context, i) {
                                      final line = state.lines[i];
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 6,
                                        ),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            PartNetworkImage(
                                              imageUrl: line.imageUrl,
                                              width: 40,
                                              height: 40,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    '${line.code} — ${line.name}',
                                                    style: const TextStyle(
                                                      fontSize: 13,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    '${l10n.available}: ${line.available} · '
                                                    '${line.lineTotal.toStringAsFixed(2)}',
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .bodySmall
                                                        ?.copyWith(
                                                          color: Theme.of(
                                                            context,
                                                          ).colorScheme
                                                              .onSurfaceVariant,
                                                        ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            SizedBox(
                                              width: 72,
                                              child: _CartLinePriceField(
                                                partId: line.partId,
                                                unitPrice: line.unitPrice,
                                                label: l10n.price,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            SizedBox(
                                              width: 100,
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  IconButton(
                                                    padding: EdgeInsets.zero,
                                                    constraints:
                                                        const BoxConstraints(
                                                      minWidth: 32,
                                                      minHeight: 32,
                                                    ),
                                                    icon: const Icon(
                                                      Icons
                                                          .remove_circle_outline,
                                                      size: 20,
                                                    ),
                                                    onPressed: () => context
                                                        .read<PosBloc>()
                                                        .add(
                                                          PosUpdateQty(
                                                            line.partId,
                                                            line.quantity - 1,
                                                          ),
                                                        ),
                                                  ),
                                                  Text(
                                                    '${line.quantity}',
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                  IconButton(
                                                    padding: EdgeInsets.zero,
                                                    constraints:
                                                        const BoxConstraints(
                                                      minWidth: 32,
                                                      minHeight: 32,
                                                    ),
                                                    icon: const Icon(
                                                      Icons
                                                          .add_circle_outline,
                                                      size: 20,
                                                    ),
                                                    onPressed: () => context
                                                        .read<PosBloc>()
                                                        .add(
                                                          PosUpdateQty(
                                                            line.partId,
                                                            line.quantity + 1,
                                                          ),
                                                        ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                          ),
                          const Divider(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                l10n.subtotal,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              Text(
                                state.subtotal.toStringAsFixed(2),
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryContainer,
                              borderRadius: BorderRadius.circular(
                                AppColors.inputRadius,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  l10n.total,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        color: AppColors.onPrimaryContainer,
                                      ),
                                ),
                                Text(
                                  state.total.toStringAsFixed(2),
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(
                                        color: AppColors.onPrimaryContainer,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          if (state.error != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              localizePosError(context, state.error),
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ],
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              OutlinedButton(
                                onPressed: () => context
                                    .read<PosBloc>()
                                    .add(const PosClearCart()),
                                child: Text(l10n.clear),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: FilledButton.icon(
                                  onPressed: state.completing ||
                                          state.lines.isEmpty
                                      ? null
                                      : () => context
                                          .read<PosBloc>()
                                          .add(PosComplete(branchId)),
                                  icon: state.completing
                                      ? const SizedBox(
                                          height: 18,
                                          width: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: AppColors.onPrimary,
                                          ),
                                        )
                                      : const Icon(Icons.check_circle_outline),
                                  label: Text(
                                    state.completing
                                        ? l10n.processing
                                        : l10n.completeSale,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
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
