import 'package:go_router/go_router.dart';

import '../core/auth/auth_cubit.dart';
import '../core/auth/auth_state.dart';
import '../core/auth/role_permissions.dart';
import '../core/connectivity/connectivity_cubit.dart';
import '../di/injection.dart';
import '../features/auth/login_screen.dart';
import '../features/branches/branches_hub_screen.dart';
import '../features/customers/customer_detail_screen.dart';
import '../features/customers/customers_hub_screen.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/invoices/invoices_screen.dart';
import '../features/parts/part_analysis_screen.dart';
import '../features/parts/parts_hub_screen.dart';
import '../features/pos/pos_screen.dart';
import '../features/pos/receipt_screen.dart';
import '../features/reports/financial_report_screen.dart';
import '../features/reports/reports_hub_screen.dart';
import '../features/reports/parts_sales_chart_screen.dart';
import '../features/reports/reports_screen.dart';
import '../features/returns/invoice_return_screen.dart';
import '../features/returns/returns_screen.dart';
import '../features/sales/sales_screen.dart';
import '../features/printer/printer_settings_screen.dart';
import '../features/settings/part_categories_screen.dart';
import '../features/settings/part_category_form_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/settings/users_screen.dart';
import '../data/models/part_category_model.dart';
import '../features/shell/app_shell.dart';
import '../features/suppliers/suppliers_hub_screen.dart';
import '../features/sync/pending_sync_screen.dart';
import 'route_paths.dart';
import 'router_refresh.dart';

GoRouter createAppRouter() {
  final authCubit = getIt<AuthCubit>();
  final connectivityCubit = getIt<ConnectivityCubit>();

  return GoRouter(
    initialLocation: RoutePaths.dashboard,
    refreshListenable: RouterRefresh(authCubit, connectivityCubit),
    redirect: (context, state) {
      final auth = authCubit.state;
      final isOnline = connectivityCubit.state.isOnline;
      final path = state.uri.path;

      if (auth.status == AuthStatus.initial ||
          auth.status == AuthStatus.loading) {
        return null;
      }

      final loggingIn = path == RoutePaths.login;
      if (!auth.isAuthenticated) {
        return loggingIn ? null : RoutePaths.login;
      }

      if (loggingIn) {
        return isOnline ? RoutePaths.dashboard : RoutePaths.pos;
      }

      if (!isOnline && !RolePermissions.isOfflineAllowed(path)) {
        return RoutePaths.pos;
      }

      final role = auth.user!.role;
      if (!RolePermissions.canAccessRoute(path, role)) {
        return RoutePaths.dashboard;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: RoutePaths.login,
        builder: (context, state) => const LoginScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: RoutePaths.dashboard,
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: RoutePaths.branches,
            builder: (context, state) => BranchesHubScreen(
              initialTabId: state.uri.queryParameters['tab'],
            ),
          ),
          GoRoute(
            path: RoutePaths.parts,
            builder: (context, state) => PartsHubScreen(
              initialTabId: state.uri.queryParameters['tab'],
            ),
            routes: [
              GoRoute(
                path: ':id/analysis',
                builder: (context, state) => PartAnalysisScreen(
                  partId: state.pathParameters['id']!,
                ),
              ),
            ],
          ),
          GoRoute(
            path: RoutePaths.inventory,
            redirect: (_, __) => '${RoutePaths.parts}?tab=stock',
          ),
          GoRoute(
            path: RoutePaths.transfers,
            redirect: (_, __) => '${RoutePaths.branches}?tab=transfers',
          ),
          GoRoute(
            path: RoutePaths.branchFinance,
            redirect: (_, __) => '${RoutePaths.branches}?tab=finance',
          ),
          GoRoute(
            path: RoutePaths.customers,
            builder: (context, state) => CustomersHubScreen(
              initialTabId: state.uri.queryParameters['tab'],
            ),
            routes: [
              GoRoute(
                path: ':id',
                builder: (context, state) => CustomerDetailScreen(
                  customerId: state.pathParameters['id']!,
                ),
              ),
            ],
          ),
          GoRoute(
            path: RoutePaths.pos,
            builder: (context, state) => const PosScreen(),
            routes: [
              GoRoute(
                path: 'receipt/:id',
                builder: (context, state) => ReceiptScreen(
                  id: state.pathParameters['id']!,
                  offline: state.uri.queryParameters['offline'] == '1',
                  amountPaid: double.tryParse(
                    state.uri.queryParameters['paid'] ?? '',
                  ),
                  changeDue: double.tryParse(
                    state.uri.queryParameters['change'] ?? '',
                  ),
                ),
              ),
            ],
          ),
          GoRoute(
            path: RoutePaths.invoices,
            redirect: (context, state) {
              if (state.uri.path == RoutePaths.invoices) {
                return '${RoutePaths.customers}?tab=invoices';
              }
              return null;
            },
            routes: [
              GoRoute(
                path: ':id',
                builder: (context, state) => InvoiceDetailScreen(
                  id: state.pathParameters['id']!,
                ),
                routes: [
                  GoRoute(
                    path: 'return',
                    builder: (context, state) => InvoiceReturnScreen(
                      invoiceId: state.pathParameters['id']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: RoutePaths.sync,
            builder: (context, state) => const PendingSyncScreen(),
          ),
          GoRoute(
            path: RoutePaths.sales,
            builder: (context, state) => const SalesScreen(),
          ),
          GoRoute(
            path: RoutePaths.settlements,
            redirect: (_, __) => '${RoutePaths.customers}?tab=settlements',
          ),
          GoRoute(
            path: RoutePaths.suppliers,
            builder: (context, state) => SuppliersHubScreen(
              initialTabId: state.uri.queryParameters['tab'],
            ),
          ),
          GoRoute(
            path: RoutePaths.purchases,
            redirect: (_, __) => '${RoutePaths.suppliers}?tab=purchases',
          ),
          GoRoute(
            path: RoutePaths.installments,
            redirect: (_, __) => '${RoutePaths.suppliers}?tab=installments',
          ),
          GoRoute(
            path: RoutePaths.returns,
            builder: (context, state) => const ReturnsScreen(),
          ),
          GoRoute(
            path: RoutePaths.reports,
            builder: (context, state) => const ReportsHubScreen(),
          ),
          GoRoute(
            path: RoutePaths.reportsFinancial,
            builder: (context, state) => const FinancialReportScreen(),
          ),
          GoRoute(
            path: RoutePaths.reportsSales,
            builder: (context, state) => const SalesReportScreen(),
          ),
          GoRoute(
            path: RoutePaths.reportsInventory,
            builder: (context, state) => const InventoryReportScreen(),
          ),
          GoRoute(
            path: RoutePaths.reportsCustomers,
            builder: (context, state) => const CustomersReportScreen(),
          ),
          GoRoute(
            path: RoutePaths.reportsSuppliers,
            builder: (context, state) => const SuppliersReportScreen(),
          ),
          GoRoute(
            path: RoutePaths.reportsReturns,
            builder: (context, state) => const ReturnsReportScreen(),
          ),
          GoRoute(
            path: RoutePaths.reportsPartsSalesChart,
            builder: (context, state) => const PartsSalesChartScreen(),
          ),
          GoRoute(
            path: RoutePaths.settings,
            builder: (context, state) => const SettingsScreen(),
            routes: [
              GoRoute(
                path: 'users',
                builder: (context, state) => const UsersScreen(),
              ),
              GoRoute(
                path: 'printer',
                builder: (context, state) => const PrinterSettingsScreen(),
              ),
              GoRoute(
                path: 'part-categories',
                builder: (context, state) => const PartCategoriesScreen(),
                routes: [
                  GoRoute(
                    path: 'new',
                    builder: (context, state) =>
                        const PartCategoryFormScreen(),
                  ),
                  GoRoute(
                    path: ':id/edit',
                    builder: (context, state) {
                      final category = state.extra as PartCategoryModel?;
                      return PartCategoryFormScreen(category: category);
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
