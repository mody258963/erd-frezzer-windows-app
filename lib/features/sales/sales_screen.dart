import 'package:flutter/material.dart';

import '../../core/l10n/api_labels.dart';
import '../../core/l10n/l10n_extension.dart';
import '../../data/local/app_database.dart';
import '../../data/models/invoice_model.dart';
import '../../data/repositories/invoice_repository.dart';
import '../../di/injection.dart';
import '../shared/entity_list_tile.dart';
import '../shared/loading_error.dart';
import '../shared/page_header.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabs;
  List<InvoiceModel>? _api;
  List<PendingInvoice>? _local;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = await getIt<InvoiceRepository>().list(perPage: 100);
      final local = await getIt<AppDatabase>().pendingFifo();
      setState(() {
        _api = api;
        _local = local;
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHeader(
          title: l10n.localSalesTitle,
          actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh))],
        ),
        TabBar(
          controller: _tabs,
          tabs: [
            Tab(text: l10n.serverTab),
            Tab(text: l10n.localPendingTab),
          ],
        ),
        Expanded(
          child: _loading
              ? const LoadingView()
              : _error != null
                  ? ErrorView(message: _error!, onRetry: _load)
                  : TabBarView(
                      controller: _tabs,
                      children: [
                        EntityListView(
                          itemCount: _api!.length,
                          emptyMessage: l10n.noData,
                          itemBuilder: (context, i) {
                            final inv = _api![i];
                            return EntityListTile(
                              title: formatMoney(context, inv.total),
                              subtitle: inv.createdAt ?? '',
                              leading: const Icon(Icons.receipt_long_outlined),
                            );
                          },
                        ),
                        EntityListView(
                          itemCount: _local!.length,
                          emptyMessage: l10n.noPendingInvoices,
                          itemBuilder: (context, i) {
                            final p = _local![i];
                            return EntityListTile(
                              title: p.localId.length > 12
                                  ? '${p.localId.substring(0, 12)}…'
                                  : p.localId,
                              subtitle: l10n.pendingRowSubtitle(
                                localizeApiStatus(context, p.status),
                                formatMoney(context, p.total),
                                '${p.createdAt}',
                              ),
                              leading: const Icon(Icons.cloud_queue),
                            );
                          },
                        ),
                      ],
                    ),
        ),
      ],
    );
  }
}
