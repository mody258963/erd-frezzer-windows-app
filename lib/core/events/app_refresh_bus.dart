/// Notifies open screens to reload server data (e.g. after return approval).
class AppRefreshBus {
  final _listeners = <void Function(AppRefreshKind)>[];

  void addListener(void Function(AppRefreshKind) listener) {
    _listeners.add(listener);
  }

  void removeListener(void Function(AppRefreshKind) listener) {
    _listeners.remove(listener);
  }

  void notify(AppRefreshKind kind) {
    for (final l in List.of(_listeners)) {
      l(kind);
    }
  }

  void notifyAll() {
    for (final kind in AppRefreshKind.values) {
      notify(kind);
    }
  }
}

enum AppRefreshKind {
  dashboard,
  inventory,
  invoices,
  settlements,
  /// Local SQLite customers/parts/stock re-synced from API.
  catalog,
  /// Admin changed global branch filter.
  branchFilter,
}
