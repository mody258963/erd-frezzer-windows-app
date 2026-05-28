import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/l10n/api_labels.dart';
import '../../core/l10n/l10n_extension.dart';
import '../../data/local/app_database.dart';
import '../../di/injection.dart';
import '../shared/entity_list_tile.dart';
import '../shared/loading_error.dart';
import '../shared/page_header.dart';
import 'sync_bloc.dart';

class PendingSyncScreen extends StatefulWidget {
  const PendingSyncScreen({super.key});

  @override
  State<PendingSyncScreen> createState() => _PendingSyncScreenState();
}

class _PendingSyncScreenState extends State<PendingSyncScreen> {
  List<PendingInvoice>? _pending;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await getIt<AppDatabase>().pendingFifo();
    setState(() {
      _pending = list;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return BlocListener<SyncBloc, SyncState>(
      listener: (context, state) {
        if (state.status == SyncStatus.done ||
            state.status == SyncStatus.partialFailure) {
          _load();
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageHeader(
            title: l10n.pendingSyncTitle,
            actions: [
              BlocBuilder<SyncBloc, SyncState>(
                builder: (context, state) {
                  return FilledButton.icon(
                    onPressed: state.status == SyncStatus.syncing
                        ? null
                        : () => getIt<SyncBloc>().add(const SyncEvent()),
                    icon: const Icon(Icons.cloud_upload),
                    label: Text(
                      state.status == SyncStatus.syncing
                          ? l10n.syncing
                          : l10n.syncNow,
                    ),
                  );
                },
              ),
            ],
          ),
          Expanded(
            child: _loading
                ? const LoadingView()
                : EntityListView(
                    itemCount: _pending?.length ?? 0,
                    emptyMessage: l10n.noPendingInvoices,
                    itemBuilder: (context, i) {
                      final p = _pending![i];
                      final shortId = p.localId.length > 8
                          ? '${p.localId.substring(0, 8)}…'
                          : p.localId;
                      return EntityListTile(
                        title: shortId,
                        subtitle: l10n.pendingRowSubtitle(
                          localizeApiStatus(context, p.status),
                          formatMoney(context, p.total),
                          '${p.createdAt}',
                        ),
                        leading: Icon(
                          p.errorMessage != null
                              ? Icons.error_outline
                              : Icons.cloud_upload_outlined,
                          color: p.errorMessage != null ? Colors.red : null,
                        ),
                        trailing: p.errorMessage != null
                            ? Tooltip(
                                message: p.errorMessage!,
                                child: const Icon(Icons.info_outline),
                              )
                            : null,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
