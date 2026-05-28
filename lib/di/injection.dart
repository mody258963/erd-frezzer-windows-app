import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/api/auth_interceptor.dart';
import '../core/api/dio_client.dart';
import '../core/auth/auth_cubit.dart';
import '../core/connectivity/connectivity_cubit.dart';
import '../core/printer/platform/windows_printer_channel.dart';
import '../core/printer/repository/printer_repository.dart';
import '../core/printer/services/invoice_printer_service.dart';
import '../core/printer/services/printer_manager.dart';
import '../core/printer/services/printer_service.dart';
import '../core/settings/settings_service.dart';
import '../core/storage/secure_storage.dart';
import '../data/local/app_database.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/branch_finance_repository.dart';
import '../data/repositories/branch_repository.dart';
import '../data/repositories/catalog_sync_repository.dart';
import '../data/repositories/customer_repository.dart';
import '../data/repositories/dashboard_repository.dart';
import '../data/repositories/installment_repository.dart';
import '../data/repositories/inventory_repository.dart';
import '../data/repositories/invoice_repository.dart';
import '../data/repositories/part_category_repository.dart';
import '../data/repositories/part_repository.dart';
import '../data/repositories/purchase_repository.dart';
import '../data/repositories/report_repository.dart';
import '../data/repositories/return_repository.dart';
import '../data/repositories/settlement_repository.dart';
import '../data/repositories/supplier_repository.dart';
import '../data/repositories/transfer_repository.dart';
import '../data/workers/sync_worker.dart';
import '../features/sync/sync_bloc.dart';

final getIt = GetIt.instance;

Future<void> setupInjection() async {
  final prefs = await SharedPreferences.getInstance();
  getIt.registerSingleton<SharedPreferences>(prefs);
  getIt.registerSingleton<SecureStorage>(SecureStorage());
  getIt.registerSingleton<SettingsService>(SettingsService(prefs));
  getIt.registerSingleton<DioClient>(
    DioClient(getIt(), getIt()),
  );
  getIt.registerSingleton<AppDatabase>(AppDatabase());

  getIt.registerLazySingleton(() => AuthRepository(getIt<DioClient>().dio, getIt()));

  getIt.registerLazySingleton<ConnectivityCubit>(
    () => ConnectivityCubit(getIt<DioClient>().dio),
  );
  getIt.registerLazySingleton<AuthCubit>(
    () => AuthCubit(getIt<AuthRepository>(), getIt<ConnectivityCubit>()),
  );
  getIt.registerLazySingleton(() => BranchRepository(getIt<DioClient>().dio));
  getIt.registerLazySingleton(() => PartRepository(getIt<DioClient>().dio));
  getIt.registerLazySingleton<PartCategoryRepository>(
    () => PartCategoryRepository(getIt<DioClient>().dio),
  );
  getIt.registerLazySingleton(() => DashboardRepository(getIt<DioClient>().dio));
  getIt.registerLazySingleton(() => InventoryRepository(getIt<DioClient>().dio));
  getIt.registerLazySingleton(() => CustomerRepository(getIt<DioClient>().dio));
  getIt.registerLazySingleton(() => InvoiceRepository(
        getIt<DioClient>().dio,
        getIt(),
        getIt<ConnectivityCubit>(),
      ));
  getIt.registerLazySingleton(() => TransferRepository(getIt<DioClient>().dio));
  getIt.registerLazySingleton(
    () => BranchFinanceRepository(getIt<DioClient>().dio),
  );
  getIt.registerLazySingleton(() => SettlementRepository(getIt<DioClient>().dio));
  getIt.registerLazySingleton(() => SupplierRepository(getIt<DioClient>().dio));
  getIt.registerLazySingleton(() => PurchaseRepository(getIt<DioClient>().dio));
  getIt.registerLazySingleton(() => InstallmentRepository(getIt<DioClient>().dio));
  getIt.registerLazySingleton(() => ReturnRepository(getIt<DioClient>().dio));
  getIt.registerLazySingleton(() => ReportRepository(getIt<DioClient>().dio));
  getIt.registerLazySingleton(
    () => CatalogSyncRepository(
      getIt<InventoryRepository>(),
      getIt<CustomerRepository>(),
      getIt<AppDatabase>(),
    ),
  );

  getIt.registerLazySingleton(
    () => SyncWorker(
      getIt<AppDatabase>(),
      getIt<InvoiceRepository>(),
      getIt<CatalogSyncRepository>(),
      getIt<ConnectivityCubit>(),
      getIt<AuthCubit>(),
    ),
  );
  getIt.registerLazySingleton(() => SyncBloc(getIt<SyncWorker>()));

  getIt.registerLazySingleton(() => WindowsPrinterChannel());
  getIt.registerLazySingleton(
    () => PrinterRepository(prefs, getIt<WindowsPrinterChannel>()),
  );
  getIt.registerLazySingleton(() => PrinterService(getIt()));
  getIt.registerLazySingleton(
    () => PrinterManager(getIt(), getIt<PrinterService>()),
  );
  getIt.registerLazySingleton(
    () => InvoicePrinterService(getIt<PrinterService>(), getIt()),
  );

  onUnauthorized = () {
    getIt<AuthCubit>().signOutLocal();
  };
}

void resetDioAfterSettingsChange() {
  getIt<DioClient>().reset();
}
