import 'package:dio/dio.dart';

import '../../core/auth/auth_cubit.dart';
import '../../core/connectivity/connectivity_cubit.dart';
import '../local/app_database.dart';
import '../repositories/catalog_sync_repository.dart';
import '../repositories/invoice_repository.dart';

class SyncResult {
  const SyncResult({
    this.synced = 0,
    this.failed = 0,
    this.stoppedForAuth = false,
    this.errors = const [],
  });

  final int synced;
  final int failed;
  final bool stoppedForAuth;
  final List<String> errors;
}

class SyncWorker {
  SyncWorker(
    this._db,
    this._invoiceRepository,
    this._catalogSync,
    this._connectivity,
    this._authCubit,
  );

  final AppDatabase _db;
  final InvoiceRepository _invoiceRepository;
  final CatalogSyncRepository _catalogSync;
  final ConnectivityCubit _connectivity;
  final AuthCubit _authCubit;

  Future<SyncResult> syncAll() async {
    if (!_connectivity.state.isOnline) {
      return const SyncResult();
    }
    final user = _authCubit.state.user;
    final branchId = user?.branchId;
    if (user == null || branchId == null) {
      return const SyncResult();
    }

    var synced = 0;
    var failed = 0;
    final errors = <String>[];

    final pending = await _db.pendingFifo();
    for (final row in pending) {
      if (row.status == 'synced') continue;
      await _db.updatePendingStatus(row.localId, status: 'syncing');
      try {
        final invoice =
            await _invoiceRepository.postPendingInvoice(row.localId);
        await _db.updatePendingStatus(
          row.localId,
          status: 'synced',
          serverInvoiceId: invoice.id,
          syncedAt: DateTime.now(),
        );
        synced++;
      } on DioException catch (e) {
        if (e.response?.statusCode == 401) {
          await _authCubit.signOutLocal();
          return SyncResult(
            synced: synced,
            failed: failed,
            stoppedForAuth: true,
            errors: errors,
          );
        }
        if (e.response?.statusCode == 422) {
          final msg = e.response?.data is Map
              ? (e.response!.data as Map)['message']?.toString()
              : 'Stock conflict';
          await _db.updatePendingStatus(
            row.localId,
            status: 'failed',
            errorMessage: msg,
          );
          failed++;
          errors.add('${row.localId}: $msg');
          continue;
        }
        await _db.updatePendingStatus(
          row.localId,
          status: 'failed',
          errorMessage: e.message,
        );
        failed++;
        errors.add('${row.localId}: ${e.message}');
      } catch (e) {
        await _db.updatePendingStatus(
          row.localId,
          status: 'failed',
          errorMessage: e.toString(),
        );
        failed++;
        errors.add('${row.localId}: $e');
      }
    }

    if (_connectivity.state.isOnline && !_authCubit.state.isAuthenticated) {
      return SyncResult(
        synced: synced,
        failed: failed,
        stoppedForAuth: true,
        errors: errors,
      );
    }

    try {
      await _catalogSync.refresh(branchId);
    } catch (_) {}

    return SyncResult(synced: synced, failed: failed, errors: errors);
  }
}
