class RoutePaths {
  static const login = '/login';
  static const dashboard = '/dashboard';
  static const branches = '/branches';
  static const parts = '/parts';
  static String partAnalysis(String partId) => '/parts/$partId/analysis';
  static const inventory = '/inventory';
  static const transfers = '/transfers';
  static const branchFinance = '/branch-finance';
  static const customers = '/customers';
  static const pos = '/pos';
  static const invoices = '/invoices';
  static const sync = '/sync';
  static const sales = '/sales';
  static const settlements = '/settlements';
  static const suppliers = '/suppliers';
  static const purchases = '/purchases';
  static const installments = '/installments';
  static const returns = '/returns';
  static const reports = '/reports';
  static const reportsSales = '/reports/sales';
  static const reportsInventory = '/reports/inventory';
  static const reportsCustomers = '/reports/customers';
  static const reportsSuppliers = '/reports/suppliers';
  static const reportsReturns = '/reports/returns';
  static const reportsPartsSalesChart = '/reports/parts-sales-chart';
  static const settings = '/settings';
  static const printerSettings = '/settings/printer';
  static const partCategories = '/settings/part-categories';
  static const partCategoryNew = '/settings/part-categories/new';
  static String partCategoryEdit(String id) =>
      '/settings/part-categories/$id/edit';
}
