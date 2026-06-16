import 'dart:async';

import '../../core/auth/auth_cubit.dart';
import '../../core/connectivity/connectivity_cubit.dart';
import '../../core/events/app_refresh_bus.dart';
import '../../data/repositories/catalog_sync_repository.dart';
import 'catalog_branch.dart';

/// Keeps local SQLite catalog aligned with the API while the app is online.
class CatalogRefreshScheduler {
  CatalogRefreshScheduler(
    this._connectivity,
    this._auth,
    this._catalog,
    this._refreshBus,
  );

  final ConnectivityCubit _connectivity;
  final AuthCubit _auth;
  final CatalogSyncRepository _catalog;
  final AppRefreshBus _refreshBus;

  Timer? _timer;
  bool _running = false;

  /// How often to pull customers, parts, and stock from the server.
  static const refreshInterval = Duration(minutes: 3);

  void start() {
    _timer?.cancel();
    _timer = Timer.periodic(refreshInterval, (_) => refreshNow());
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  /// Immediate catalog sync (POS open, sync button, timer).
  Future<void> refreshNow() async {
    if (_running) return;
    if (!_connectivity.state.isOnline) return;
    if (!_auth.state.isAuthenticated) return;

    final branchId = await resolveCatalogBranchId(_auth.state.user);
    if (branchId == null) return;

    _running = true;
    try {
      await _catalog.refresh(branchId);
      _refreshBus.notify(AppRefreshKind.catalog);
    } catch (_) {
      // Offline or API error — keep last local snapshot.
    } finally {
      _running = false;
    }
  }
}
