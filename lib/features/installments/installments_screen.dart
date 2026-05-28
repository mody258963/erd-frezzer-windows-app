import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/auth/auth_cubit.dart';
import '../../core/auth/role_permissions.dart';
import '../../core/l10n/api_labels.dart';
import '../../core/l10n/l10n_extension.dart';
import '../../data/models/user_role.dart';
import '../../data/repositories/installment_repository.dart';
import '../../di/injection.dart';
import '../shared/entity_list_tile.dart';
import '../shared/loading_error.dart';
import '../shared/page_header.dart';
import '../shared/status_chip.dart';

class InstallmentsScreen extends StatefulWidget {
  const InstallmentsScreen({super.key});

  @override
  State<InstallmentsScreen> createState() => _InstallmentsScreenState();
}

class _InstallmentsScreenState extends State<InstallmentsScreen> {
  List<Map<String, dynamic>>? _items;
  String? _error;
  bool _loading = true;
  bool _overdueOnly = false;

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
      final repo = getIt<InstallmentRepository>();
      final items = _overdueOnly ? await repo.overdue() : await repo.list();
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
    final role = context.read<AuthCubit>().state.user?.role ?? UserRole.salesperson;
    final canPay = RolePermissions.canPerform(AppAction.installmentPay, role);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHeader(
          title: l10n.installmentsTitle,
          actions: [
            FilterChip(
              label: Text(l10n.overdue),
              selected: _overdueOnly,
              onSelected: (v) {
                setState(() => _overdueOnly = v);
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
                        final item = _items![i];
                        final id = item['id'] as String;
                        final status = item['status'] as String? ?? '';
                        final amount = item['amount'];
                        return EntityListTile(
                          title: formatMoney(context, amount is num ? amount : null),
                          subtitle: l10n.dueDate('${item['due_date']}'),
                          leading: const Icon(Icons.payments_outlined),
                          trailing: canPay && status != 'paid'
                              ? FilledButton(
                                  onPressed: () async {
                                    await getIt<InstallmentRepository>().pay(id);
                                    await _load();
                                  },
                                  child: Text(l10n.pay),
                                )
                              : StatusChip(
                                  label: localizeApiStatus(context, status),
                                  variant: status == 'paid'
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
