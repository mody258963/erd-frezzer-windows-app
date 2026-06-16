import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'app.dart';
import 'core/logging/app_logger.dart';
import 'core/auth/auth_cubit.dart';
import 'core/connectivity/connectivity_cubit.dart';
import 'core/catalog/catalog_branch.dart';
import 'data/repositories/catalog_sync_repository.dart';
import 'core/printer/services/printer_manager.dart';
import 'di/injection.dart';
import 'features/sync/sync_bloc.dart';
import 'core/catalog/catalog_refresh_scheduler.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kDebugMode) {
    AppLogger.configure();
  }

  await setupInjection();
  try {
    await getIt<PrinterManager>().reconnectIfConfigured();
  } catch (_) {}
  await getIt<AuthCubit>().loadSession();
  await getIt<ConnectivityCubit>().checkConnectivity();

  final auth = getIt<AuthCubit>().state;
  if (getIt<ConnectivityCubit>().state.isOnline && auth.isAuthenticated) {
    final branchId = await resolveCatalogBranchId(auth.user);
    if (branchId != null) {
      try {
        await getIt<CatalogSyncRepository>().refresh(branchId);
      } catch (_) {}
    }
    getIt<SyncBloc>().add(const SyncEvent());
    getIt<CatalogRefreshScheduler>().start();
  }

  runApp(const FrostPartsApp());
}
