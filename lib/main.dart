import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

import 'app.dart';
import 'core/auth/auth_cubit.dart';
import 'core/connectivity/connectivity_cubit.dart';
import 'data/repositories/catalog_sync_repository.dart';
import 'core/printer/services/printer_manager.dart';
import 'di/injection.dart';
import 'features/sync/sync_bloc.dart';

void _configureLogging() {
  Logger.root.level = Level.INFO;
  Logger.root.onRecord.listen((record) {
    if (kDebugMode) {
      debugPrint(
        '[${record.loggerName}] ${record.level.name}: ${record.message}',
      );
    }
  });
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _configureLogging();

  await setupInjection();
  try {
    await getIt<PrinterManager>().reconnectIfConfigured();
  } catch (_) {}
  await getIt<AuthCubit>().loadSession();
  await getIt<ConnectivityCubit>().checkConnectivity();

  final auth = getIt<AuthCubit>().state;
  if (getIt<ConnectivityCubit>().state.isOnline &&
      auth.isAuthenticated &&
      auth.user?.branchId != null) {
    try {
      await getIt<CatalogSyncRepository>().refresh(auth.user!.branchId!);
    } catch (_) {}
    getIt<SyncBloc>().add(const SyncEvent());
  }

  runApp(const FrostPartsApp());
}
