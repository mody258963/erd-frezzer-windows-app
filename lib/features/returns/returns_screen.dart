import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_cubit.dart';
import '../../core/auth/role_permissions.dart';
import '../../core/l10n/api_labels.dart';
import '../../core/l10n/l10n_extension.dart';
import '../../core/events/app_refresh_bus.dart';
import '../../core/logging/app_logger.dart';
import '../../core/printer/printer_print_helper.dart';
import '../../core/utils/return_approval_helper.dart';
import '../../router/route_paths.dart';
import 'approve_return_dialog.dart';
import 'package:dio/dio.dart';
import '../../data/models/invoice_model.dart';
import '../../data/models/user_role.dart';
import '../../data/repositories/invoice_repository.dart';
import '../../data/repositories/return_repository.dart';
import '../../di/injection.dart';
import '../shared/entity_list_tile.dart';
import '../shared/loading_error.dart';
import '../shared/page_header.dart';
import '../shared/status_chip.dart';

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
    getIt<AppRefreshBus>().addListener(_onAppRefresh);
    _load();
  }

  @override
  void dispose() {
    getIt<AppRefreshBus>().removeListener(_onAppRefresh);
    super.dispose();
  }

  void _onAppRefresh(AppRefreshKind kind) {
    if (!mounted || kind != AppRefreshKind.branchFilter) return;
    _load();
  }

  Future<void> _approveReturn(Map<String, dynamic> row) async {
    final l10n = context.l10n;
    final id = row['id'] as String;
    var returnRow = row;

    List<ReturnLineInfo> lines = parseReturnItems(returnRow);
    if (lines.isEmpty) {
      try {
        final detail = await getIt<ReturnRepository>().get(id);
        lines = parseReturnItems(detail);
        returnRow = detail;
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
        return;
      }
    }

    if (!mounted) return;

    final resolution = await ApproveReturnDialog.show(
      context,
      returnRow: returnRow,
      lines: lines,
    );
    if (resolution == null || !mounted) return;

    AppLogger.action('returns.approve', {'id': id, 'resolution': resolution});

    try {
      await getIt<ReturnRepository>().approve(id, resolution: resolution);
      if (!mounted) return;

      await _refreshLinkedInvoice(returnRow);

      if (!mounted) return;

      getIt<AppRefreshBus>().notify(AppRefreshKind.dashboard);
      getIt<AppRefreshBus>().notify(AppRefreshKind.inventory);
      getIt<AppRefreshBus>().notify(AppRefreshKind.invoices);

      final invoiceId = invoiceIdFromReturnRow(returnRow);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.returnApprovedRefresh),
          backgroundColor: Colors.green.shade700,
          action: invoiceId != null
              ? SnackBarAction(
                  label: l10n.reprintInvoice,
                  onPressed: () => _reprintInvoice(invoiceId),
                )
              : null,
        ),
      );
      await _load();
    } on DioException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLogger.dioMessage(e))),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    }
  }

  Future<void> _reprintInvoice(String invoiceId) async {
    final l10n = context.l10n;
    try {
      await printInvoiceReceiptById(invoiceId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.printSuccess)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.printFailed(e.toString()))),
      );
    }
  }

  Future<void> _refreshLinkedInvoice(Map<String, dynamic> returnRow) async {
    final invoiceId = invoiceIdFromReturnRow(returnRow);
    if (invoiceId == null) return;
    AppLogger.action('returns.refreshInvoice', {'invoiceId': invoiceId});
    try {
      await getIt<InvoiceRepository>().get(invoiceId);
    } catch (e) {
      AppLogger.warning('returns.refreshInvoice.failed', e);
    }
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

  Future<void> _create() async {
    final l10n = context.l10n;
    final role = context.read<AuthCubit>().state.user?.role ?? UserRole.salesperson;
    if (!RolePermissions.canPerform(AppAction.returnCreate, role)) return;

    List<InvoiceModel> invoices;
    try {
      final all = await getIt<InvoiceRepository>().list(perPage: 100);
      invoices = all.where((i) => i.canCreateReturn).toList();
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
        SnackBar(content: Text(l10n.noInvoicesAvailableForReturn)),
      );
      return;
    }

    if (!mounted) return;

    final selectedId = await showDialog<String?>(
      context: context,
      builder: (ctx) => _InvoicePickerDialog(
        invoices: invoices,
        invoiceLabel: (inv) => _invoiceLabel(ctx, inv),
      ),
    );

    if (selectedId == null || !mounted) return;

    final created = await context.push<bool>(RoutePaths.invoiceReturn(selectedId));
    if (created == true && mounted) {
      await _load();
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
                                      onPressed: () => _approveReturn(r),
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

class _InvoicePickerDialog extends StatefulWidget {
  const _InvoicePickerDialog({
    required this.invoices,
    required this.invoiceLabel,
  });

  final List<InvoiceModel> invoices;
  final String Function(InvoiceModel) invoiceLabel;

  @override
  State<_InvoicePickerDialog> createState() => _InvoicePickerDialogState();
}

class _InvoicePickerDialogState extends State<_InvoicePickerDialog> {
  late String _selectedId;

  @override
  void initState() {
    super.initState();
    _selectedId = widget.invoices.firstWhere(
      (i) => i.canReturnPartial || i.canCreateReturn,
      orElse: () => widget.invoices.first,
    ).id;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final selected = widget.invoices.firstWhere((i) => i.id == _selectedId);

    return AlertDialog(
      title: Text(l10n.newReturn),
      content: SizedBox(
        width: 420,
        child: DropdownButtonFormField<String>(
          initialValue: _selectedId,
          decoration: InputDecoration(labelText: l10n.selectInvoice),
          isExpanded: true,
          items: [
            for (final inv in widget.invoices)
              DropdownMenuItem(
                value: inv.id,
                enabled: inv.canCreateReturn,
                child: Text(
                  inv.isReturned
                      ? '${widget.invoiceLabel(inv)} · ${l10n.invoiceReturnStatusReturned}'
                      : widget.invoiceLabel(inv),
                ),
              ),
          ],
          onChanged: (id) {
            if (id != null) setState(() => _selectedId = id);
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: selected.canCreateReturn
              ? () => Navigator.pop(context, _selectedId)
              : null,
          child: Text(l10n.create),
        ),
      ],
    );
  }
}
