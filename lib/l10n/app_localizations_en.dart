// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Noor Al-Islam';

  @override
  String get appSubtitle => 'ERB-Frezzer ERP';

  @override
  String get appTagline =>
      'Inventory, sales, and branch operations\nin one desktop workspace.';

  @override
  String get welcomeBack => 'Welcome back';

  @override
  String get signInToContinue => 'Sign in to continue';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get signIn => 'Sign in';

  @override
  String get online => 'Online';

  @override
  String get offline => 'Offline';

  @override
  String get offlineBanner => 'Offline â€” only new sales can be saved locally';

  @override
  String get dismiss => 'Dismiss';

  @override
  String get sync => 'Sync';

  @override
  String get logout => 'Logout';

  @override
  String get branch => 'Branch';

  @override
  String get user => 'User';

  @override
  String get navDashboard => 'Dashboard';

  @override
  String get navPos => 'POS';

  @override
  String get navParts => 'Parts';

  @override
  String get navStock => 'Stock';

  @override
  String get navPartsStock => 'Parts & stock';

  @override
  String get navCustomers => 'Customers';

  @override
  String get navSales => 'Sales';

  @override
  String get navSettle => 'Settlements';

  @override
  String get navSupply => 'Suppliers';

  @override
  String get navPurchases => 'Purchases';

  @override
  String get navReturns => 'Returns';

  @override
  String get navReports => 'Reports';

  @override
  String get navBranches => 'Branches';

  @override
  String get navTransfers => 'Transfers';

  @override
  String get navBranchFinance => 'Branch finance';

  @override
  String get navInstallments => 'Installments';

  @override
  String get navPending => 'Pending';

  @override
  String get navLocalSales => 'Local sales';

  @override
  String get navSettings => 'Settings';

  @override
  String get dashboardTitle => 'Dashboard';

  @override
  String get dashboardSubtitle =>
      'Your business at a glance â€” sales, stock, and money';

  @override
  String get dashboardNeedsAttention => 'Needs attention';

  @override
  String get dashboardAllClear => 'All clear';

  @override
  String get activityLogTitle => 'Activity log';

  @override
  String get activityLogSubtitle => 'What changed recently in your store';

  @override
  String get activityInvoiceCreated => 'New sale recorded';

  @override
  String get activityInvoiceUpdated => 'Sale updated';

  @override
  String get activityInvoiceCancelled => 'Sale cancelled';

  @override
  String get activityInventoryAdjusted => 'Stock quantity adjusted';

  @override
  String get activityPurchaseCreated => 'Purchase order created';

  @override
  String get activityPurchaseReceived => 'Purchase received into stock';

  @override
  String get activityCustomerCreated => 'New customer added';

  @override
  String get activityCustomerUpdated => 'Customer updated';

  @override
  String get activitySettlementRecorded => 'Customer payment recorded';

  @override
  String get activityTransferCreated => 'Stock transfer created';

  @override
  String get activityTransferCompleted => 'Stock transfer completed';

  @override
  String get activityReturnApproved => 'Product return approved';

  @override
  String get activityReturnRejected => 'Product return rejected';

  @override
  String get activityPartCreated => 'New part added to catalog';

  @override
  String get activityPartUpdated => 'Part information updated';

  @override
  String get activitySupplierCreated => 'New supplier added';

  @override
  String get activitySyncCompleted => 'Data sync completed';

  @override
  String get activityOwnerCashOut => 'Owner cash out recorded';

  @override
  String activityGeneric(Object action, Object entity) {
    return '$action Â· $entity';
  }

  @override
  String get entityInvoice => 'Sales';

  @override
  String get entityStock => 'Inventory';

  @override
  String get entityCustomer => 'Customers';

  @override
  String get entityPurchase => 'Purchases';

  @override
  String get entitySupplier => 'Suppliers';

  @override
  String get entityPart => 'Parts';

  @override
  String get entityTransfer => 'Transfers';

  @override
  String get entityReturn => 'Returns';

  @override
  String get entitySettlement => 'Settlements';

  @override
  String get entityBranch => 'Branches';

  @override
  String get noDebtors => 'No outstanding customer balances';

  @override
  String get noCreditors => 'No outstanding supplier balances';

  @override
  String get noStockAlerts => 'Stock levels look healthy';

  @override
  String get openPos => 'Open POS';

  @override
  String get viewInventory => 'View inventory';

  @override
  String get todaySales => 'Today sales';

  @override
  String get todayProfit => 'Today\'s profit';

  @override
  String get weeklyProfit => 'Weekly profit';

  @override
  String get weeklyRevenue => 'Weekly revenue';

  @override
  String get weeklyCost => 'Weekly cost';

  @override
  String get profitAmount => 'Profit';

  @override
  String get todayCost => 'Cost of goods (today)';

  @override
  String get todayInvoices => 'Invoices today';

  @override
  String get todayProfitEstimated =>
      'Calculated from today\'s sales and part costs';

  @override
  String profitMargin(Object percent) {
    return 'Margin: $percent%';
  }

  @override
  String get lowStock => 'Low stock';

  @override
  String get overdueInstallments => 'Overdue installments';

  @override
  String get pendingCredit => 'Pending credit';

  @override
  String get salesTrend => 'Sales trend';

  @override
  String get recentActivity => 'Recent activity';

  @override
  String get noRecentActivity => 'No recent activity';

  @override
  String get loadingDashboard => 'Loading dashboardâ€¦';

  @override
  String get posTitle => 'POS â€” New sale';

  @override
  String get posSubtitle => 'Search parts or scan a barcode to add to cart';

  @override
  String get printDaySales => 'Print day sales';

  @override
  String get printDaySalesReport => 'Day sales report';

  @override
  String get noDaySales => 'No sales today to print';

  @override
  String get daySalesPrinted => 'Day sales report sent to printer';

  @override
  String get searchScanBarcode => 'Search / scan barcode';

  @override
  String get searchPartToAdd => 'Search for a part to add';

  @override
  String get cart => 'Cart';

  @override
  String get customer => 'Customer';

  @override
  String get cash => 'Cash';

  @override
  String get credit => 'Credit';

  @override
  String get discount => 'Discount';

  @override
  String get cartEmpty => 'Cart is empty';

  @override
  String get removeFromCart => 'Remove item';

  @override
  String get subtotal => 'Subtotal';

  @override
  String get total => 'Total';

  @override
  String get clear => 'Clear';

  @override
  String get completeSale => 'Complete sale';

  @override
  String get amountReceived => 'Amount received';

  @override
  String get changeDue => 'Change due';

  @override
  String get amountReceivedTooLow =>
      'Amount received must be at least the invoice total';

  @override
  String get processing => 'Processingâ€¦';

  @override
  String get invalidLinePrice =>
      'Enter a price greater than zero for each cart line';

  @override
  String get price => 'Price';

  @override
  String get available => 'Avail';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsSubtitle => 'Application preferences and sync';

  @override
  String get apiConnection => 'API connection';

  @override
  String get apiHostHint => 'Host only â€” /api/v1 is appended automatically';

  @override
  String get apiBaseUrl => 'API base URL';

  @override
  String get offlineCashOnly => 'Offline cash-only';

  @override
  String get offlineCashOnlyHint => 'Block credit payments when offline';

  @override
  String get lastCatalogSync => 'Last catalog sync';

  @override
  String get never => 'Never';

  @override
  String get saveSettings => 'Save settings';

  @override
  String get settingsSaved => 'Settings saved';

  @override
  String get language => 'Language';

  @override
  String get languageArabic => 'Arabic';

  @override
  String get languageEnglish => 'English';

  @override
  String get printerSettings => 'Printer settings';

  @override
  String get openPrinterSettings => 'Configure printer';

  @override
  String get customersTitle => 'Customers';

  @override
  String get search => 'Search';

  @override
  String get newCustomer => 'New customer';

  @override
  String get customerBranchRequired =>
      'Select a branch before adding a customer';

  @override
  String get inventoryTitle => 'Inventory';

  @override
  String get lowStockFilter => 'Low stock';

  @override
  String get adjust => 'Adjust';

  @override
  String get receipt => 'Receipt';

  @override
  String get receiptPending => 'Receipt (Pending sync)';

  @override
  String get newSale => 'New sale';

  @override
  String get printReceipt => 'Print receipt';

  @override
  String get printing => 'Printingâ€¦';

  @override
  String get printSuccess => 'Receipt sent to printer';

  @override
  String printFailed(String error) {
    return 'Print failed: $error';
  }

  @override
  String get somethingWentWrong => 'Something went wrong';

  @override
  String get tryAgain => 'Try again';

  @override
  String get nothingHereYet => 'Nothing here yet';

  @override
  String get printerDiscovery => 'Discover printers';

  @override
  String get printerRefresh => 'Refresh list';

  @override
  String get printerSelect => 'Select printer';

  @override
  String get printerConnect => 'Connect';

  @override
  String get printerDisconnect => 'Disconnect';

  @override
  String get printerConnected => 'Connected';

  @override
  String get printerDisconnected => 'Disconnected';

  @override
  String get printerNotConnected => 'Printer not connected';

  @override
  String get paperWidth => 'Paper width';

  @override
  String get paperWidth58 => '58 mm';

  @override
  String get paperWidth80 => '80 mm';

  @override
  String get companyName => 'Company name';

  @override
  String get footerText => 'Footer';

  @override
  String get phoneNumber => 'Phone number';

  @override
  String get printTestPage => 'Print test page';

  @override
  String get savePrinterSettings => 'Save printer settings';

  @override
  String get printerSettingsSaved => 'Printer settings saved';

  @override
  String get noPrintersFound => 'No printers found';

  @override
  String get autoPrintOnSale => 'Auto-print after sale';

  @override
  String get currencyEgp => 'EGP';

  @override
  String get invoiceNumber => 'Invoice #';

  @override
  String get date => 'Date';

  @override
  String get items => 'Items';

  @override
  String get payment => 'Payment';

  @override
  String get partsTitle => 'Parts';

  @override
  String get invoicesTitle => 'Sales';

  @override
  String get localSalesTitle => 'Local sales';

  @override
  String get suppliersTitle => 'Suppliers';

  @override
  String get suppliersSubtitle =>
      'Suppliers registered in the selected branch only';

  @override
  String get supplierBranchRequired =>
      'Select a branch before adding a supplier';

  @override
  String get supplierBranchPoHint => 'No suppliers in this branch yet';

  @override
  String get newSupplier => 'New supplier';

  @override
  String get editSupplier => 'Edit supplier';

  @override
  String get supplierName => 'Name';

  @override
  String get supplierAddress => 'Address';

  @override
  String get supplierEmail => 'Email';

  @override
  String get supplierDebt => 'Outstanding debt';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get close => 'Close';

  @override
  String get edit => 'Edit';

  @override
  String get delete => 'Delete';

  @override
  String get nameRequired => 'Name is required';

  @override
  String get supplierSaved => 'Supplier saved';

  @override
  String get supplierDeleted => 'Supplier deleted';

  @override
  String get contactPerson => 'Contact person';

  @override
  String get purchasesTitle => 'Purchase orders';

  @override
  String get newPurchase => 'New purchase';

  @override
  String get purchaseOrder => 'PO';

  @override
  String get purchaseSaved => 'Purchase order created';

  @override
  String get supplier => 'Supplier';

  @override
  String get description => 'Description';

  @override
  String get paymentImmediate => 'Immediate';

  @override
  String get paymentInstallments => 'Installments';

  @override
  String get installmentCount => 'Installment count';

  @override
  String get installmentStartDate => 'First installment date';

  @override
  String get lineItems => 'Line items';

  @override
  String get part => 'Part';

  @override
  String get qty => 'Qty';

  @override
  String get unitCost => 'Unit cost';

  @override
  String get addLine => 'Add line';

  @override
  String get receive => 'Receive';

  @override
  String get noSuppliersHint => 'Create a supplier first';

  @override
  String get branchRequired => 'Your user must have a branch assigned';

  @override
  String get addAtLeastOneLine => 'Add at least one line item';

  @override
  String get receivablesTitle => 'Receivables (customers)';

  @override
  String get payablesTitle => 'Payables (suppliers)';

  @override
  String get inventoryAlertsTitle => 'Inventory alerts';

  @override
  String get totalReceivable => 'Total receivable';

  @override
  String get totalPayable => 'Total payable';

  @override
  String get topDebtors => 'Top debtors';

  @override
  String get topCreditors => 'Top creditors';

  @override
  String get configurePrinterFirst => 'Configure printer in Settings first';

  @override
  String get name => 'Name';

  @override
  String get active => 'Active';

  @override
  String get inactive => 'Inactive';

  @override
  String get create => 'Create';

  @override
  String get newAction => 'New';

  @override
  String get noData => 'No data';

  @override
  String get balance => 'Balance';

  @override
  String balanceValue(Object amount) {
    return 'Balance: $amount';
  }

  @override
  String get editCustomer => 'Edit customer';

  @override
  String get customerType => 'Customer type';

  @override
  String get creditLimit => 'Credit limit';

  @override
  String customerRowSubtitle(Object type, Object balance) {
    return '$type Â· $balance';
  }

  @override
  String get customerSaved => 'Customer saved';

  @override
  String get contactInfo => 'Contact';

  @override
  String get purchaseHistory => 'Purchase history';

  @override
  String get purchaseHistoryHint =>
      'Parts this customer bought â€” when and at which branch.';

  @override
  String get noPurchaseHistory =>
      'No purchases recorded for this customer yet.';

  @override
  String get totalPurchases => 'Total purchases';

  @override
  String get tapRowForInvoice => 'Tap a row to open the full invoice.';

  @override
  String get customerViewThisWeek => 'This week';

  @override
  String get customerViewHistory => 'Settled / history';

  @override
  String customerThisWeekHint(Object range) {
    return 'Open work for $range â€” unsettled invoices only.';
  }

  @override
  String get customerHistoryHint =>
      'Settled invoices and purchases from earlier weeks.';

  @override
  String get customerOpenWork => 'This week\'s work';

  @override
  String get customerSettledHistory => 'Settled & history';

  @override
  String get customerSettledHistoryHint =>
      'Invoices paid via settlement or from before this week.';

  @override
  String get customerNoOpenWorkThisWeek =>
      'No open invoices this week â€” all settled or none sold yet.';

  @override
  String get customerNoSettledHistory => 'No settled or older invoices yet.';

  @override
  String customerWeekRange(Object from, Object to) {
    return '$from â€“ $to';
  }

  @override
  String get customerNoWeekInvoices => 'No invoices this week to print.';

  @override
  String get printWeekInvoices => 'Print all (one job)';

  @override
  String weekInvoicesPrinted(Object count) {
    return 'Printed $count invoice(s)';
  }

  @override
  String get settled => 'Settled';

  @override
  String get reportThisWeek => 'This week';

  @override
  String get collectPaymentTitle => 'Collect payment';

  @override
  String get collectPaymentConfirm => 'Collect';

  @override
  String get collectPaymentSuccess => 'Payment recorded';

  @override
  String get customerNoBalanceDue => 'No balance due';

  @override
  String customerPayAmountInvalid(Object max) {
    return 'Amount must be between 0.01 and $max';
  }

  @override
  String get customerPaymentHistory => 'Payment history';

  @override
  String get unpaidInvoicesTitle => 'Unpaid invoices';

  @override
  String get unpaidInvoicesHint =>
      'Partial payments apply to oldest invoices first.';

  @override
  String invoiceBalanceSubtitle(Object paid, Object due) {
    return 'Paid $paid Â· Due $due';
  }

  @override
  String get refundProfitImpact => 'Return margin impact';

  @override
  String get linkToSupplier => 'Link to supplier';

  @override
  String get noLinkedSupplier => 'No linked supplier';

  @override
  String get linkedBalanceTitle => 'Net balance (linked)';

  @override
  String get linkedNotLinkedHint =>
      'Link this customer to a supplier to see net balance and offset.';

  @override
  String linkedToSupplier(Object name) {
    return 'Linked supplier: $name';
  }

  @override
  String linkedToCustomer(Object name) {
    return 'Linked customer: $name';
  }

  @override
  String get linkedCustomerReceivable => 'They owe you';

  @override
  String get linkedSupplierPayable => 'You owe them';

  @override
  String get linkedNetBalance => 'Net balance';

  @override
  String netTheyOweUs(Object amount) {
    return 'For us $amount';
  }

  @override
  String netWeOweThem(Object amount) {
    return 'On us $amount';
  }

  @override
  String get netBalanced => 'Balanced';

  @override
  String get offsetSupplierTitle => 'Offset / contra settlement';

  @override
  String get offsetSupplierAction => 'Offset (Ù…Ù‚Ø§ØµØ©)';

  @override
  String get offsetAmountLabel => 'Offset amount';

  @override
  String offsetFullAmount(Object amount) {
    return 'Offset full $amount';
  }

  @override
  String offsetAmountInvalid(Object max) {
    return 'Amount must be between 0.01 and $max';
  }

  @override
  String get offsetNotAvailable => 'Nothing to offset';

  @override
  String get offsetConfirm => 'Offset';

  @override
  String get offsetSuccess => 'Offset recorded';

  @override
  String get purchaseAlreadyReceived => 'This order was already received.';

  @override
  String get installmentAlreadyPaid => 'Installment already paid.';

  @override
  String get installmentPaidSuccess => 'Installment paid.';

  @override
  String payInstallmentTitle(Object no) {
    return 'Pay installment #$no';
  }

  @override
  String get payInstallmentTitleGeneric => 'Pay installment';

  @override
  String get installmentScheduled => 'Scheduled';

  @override
  String get installmentAlreadyPaidAmount => 'Already paid';

  @override
  String get installmentBalanceDue => 'Balance due';

  @override
  String get payAmountLabel => 'Pay amount';

  @override
  String payFullBalance(Object amount) {
    return 'Pay full balance ($amount)';
  }

  @override
  String installmentPayAmountInvalid(Object max) {
    return 'Amount must be between 0.01 and $max';
  }

  @override
  String get returnResolution => 'Resolution';

  @override
  String get resolutionRestock => 'Restock inventory';

  @override
  String get resolutionCreditNote => 'Credit note (reduce customer balance)';

  @override
  String get resolutionRefundCash => 'Refund cash';

  @override
  String get resolutionReplace => 'Replace item';

  @override
  String get resolutionWriteoff => 'Write off (no restock)';

  @override
  String get resolutionSupplierCredit => 'Supplier credit (reduce payables)';

  @override
  String get returnDefectiveHint =>
      'Defective items are not restocked. Use Write off or Refund cash so the customer gets their money back.';

  @override
  String get returnLinesSummary => 'Return lines';

  @override
  String get returnApprovedRefresh =>
      'Return approved. Inventory and dashboard will refresh.';

  @override
  String get resolutionHintRestockOnly =>
      'Stock increases at the branch. No cash refund on the dashboard.';

  @override
  String get resolutionHintRefundOnly =>
      'Customer refund is deducted from dashboard totals.';

  @override
  String get resolutionHintRestockAndRefund =>
      'Stock increases and customer refund applies (cash / credit note).';

  @override
  String get resolutionHintWriteoffDefective =>
      'Defective: no restock. Customer receives refund (unit price Ã— qty).';

  @override
  String get resolutionHintReplace =>
      'Replacement â€” no automatic stock or refund in this resolution.';

  @override
  String get weeklyCustomerRefunds => 'Weekly customer refunds';

  @override
  String get weeklyNetSales => 'Weekly net sales';

  @override
  String get invoiceReturnStatusReturned => 'Fully returned';

  @override
  String get invoiceReturnStatusPartial => 'Partial return';

  @override
  String get quantitySold => 'Sold';

  @override
  String get quantityAvailableForReturn => 'Available to return';

  @override
  String get quantityReturned => 'Returned';

  @override
  String get quantityRemaining => 'Remaining';

  @override
  String get returnRefundTotal => 'Refund total';

  @override
  String get reprintInvoice => 'Reprint invoice';

  @override
  String get returnItemsTitle => 'Return items';

  @override
  String returnQuantityExceeded(Object available) {
    return 'You can only return $available more of this item.';
  }

  @override
  String get returnsOnInvoice => 'Returns on this invoice';

  @override
  String get netAfterReturns => 'Net after returns';

  @override
  String get originalTotal => 'Original total';

  @override
  String get returnedCompleted => 'Returned (completed)';

  @override
  String soldQtyLabel(Object qty) {
    return 'Sold $qty';
  }

  @override
  String availableQtyLabel(Object qty) {
    return 'Available: $qty';
  }

  @override
  String returnedQtyLabel(Object completed, Object pending) {
    return 'Returned: $completed (pending $pending)';
  }

  @override
  String get invoiceAlreadyReturned =>
      'This invoice was already returned. Choose another invoice.';

  @override
  String invoiceReturnStatusLabel(Object status) {
    return 'Return status: $status';
  }

  @override
  String get noInvoicesAvailableForReturn =>
      'No invoices available for return (all returned or cancelled).';

  @override
  String get branchesTitle => 'Branches';

  @override
  String get newBranch => 'New branch';

  @override
  String get editBranch => 'Edit branch';

  @override
  String get returnsTitle => 'Product returns';

  @override
  String get newReturn => 'New return';

  @override
  String get returnSaved => 'Return submitted for approval';

  @override
  String get selectInvoice => 'Invoice';

  @override
  String invoicePickerLabel(Object id, Object customer, Object total) {
    return '$id Â· $customer Â· $total';
  }

  @override
  String get returnReason => 'Reason';

  @override
  String get rejectReason => 'Rejection reason';

  @override
  String get returnTypeCustomer => 'Customer return';

  @override
  String get returnTypeSupplier => 'Supplier return';

  @override
  String get returnCondition => 'Item condition';

  @override
  String get conditionSellable => 'Sellable';

  @override
  String get conditionDefective => 'Defective';

  @override
  String get returnQty => 'Return qty';

  @override
  String get noInvoiceLines => 'This invoice has no line items';

  @override
  String get selectReturnLines => 'Enter return quantity for at least one item';

  @override
  String get approve => 'Approve';

  @override
  String get reject => 'Reject';

  @override
  String returnRowTitle(Object type, Object status) {
    return '$type â€” $status';
  }

  @override
  String get reason => 'Reason';

  @override
  String get installmentsTitle => 'Installments';

  @override
  String get overdue => 'Overdue';

  @override
  String get pay => 'Pay';

  @override
  String dueDate(Object date) {
    return 'Due $date';
  }

  @override
  String amountLabel(Object amount) {
    return 'Amount: $amount';
  }

  @override
  String get settlementsTitle => 'Settlements';

  @override
  String get settlementsSubtitle =>
      'Collect credit customer balances — daily or weekly (Saturday) cycles';

  @override
  String get settlementsDueTab => 'Due now';

  @override
  String get settlementsHistoryTab => 'History';

  @override
  String get settlementsUpcomingEmpty => 'No customers due for collection';

  @override
  String get settlementsFilterAll => 'All due';

  @override
  String get settlementsFilterDaily => 'Daily';

  @override
  String get settlementsFilterWeekly => 'Weekly';

  @override
  String get settlementCycleLabel => 'Settlement cycle';

  @override
  String get settlementCycleWeekly => 'Weekly (Saturday)';

  @override
  String get settlementCycleDaily => 'Daily';

  @override
  String get lastSettledAt => 'Last collected';

  @override
  String get amountDue => 'Amount due';

  @override
  String get settleAll => 'Settle all';

  @override
  String get partialPay => 'Partial pay';

  @override
  String get recordSettlement => 'Record settlement';

  @override
  String get selectCustomer => 'Customer';

  @override
  String get settlementCreditHint =>
      'Only credit customers are listed. Saving settles all unpaid credit invoices for that customer.';

  @override
  String get noCreditCustomers =>
      'No credit customers. Add a customer with type Credit on the Customers screen.';

  @override
  String get settlementSaved => 'Settlement recorded';

  @override
  String get settlementCreditOnly =>
      'Settlements apply to credit customers only';

  @override
  String get settlementNoUnpaidInvoices =>
      'No unpaid credit invoices for this customer';

  @override
  String get paymentMethod => 'Payment method';

  @override
  String get bankTransfer => 'Bank transfer';

  @override
  String get paymentCheck => 'Check';

  @override
  String get notesOptional => 'Notes (optional)';

  @override
  String get customerId => 'Customer ID';

  @override
  String settlementRowSubtitle(Object date, Object amount) {
    return '$date Â· $amount';
  }

  @override
  String get transfersTitle => 'Stock transfers';

  @override
  String get newTransfer => 'New transfer';

  @override
  String get fromBranchId => 'From branch ID';

  @override
  String get toBranchId => 'To branch ID';

  @override
  String get fromBranch => 'From branch';

  @override
  String get toBranch => 'To branch';

  @override
  String transferBranches(Object from, Object to) {
    return '$from â†’ $to';
  }

  @override
  String get selectBranch => 'Select a branch';

  @override
  String get failedLoadBranches => 'Could not load branches';

  @override
  String get selectPart => 'Part / item';

  @override
  String get failedLoadParts => 'Could not load parts';

  @override
  String get noPartsAvailable => 'No parts available at this branch';

  @override
  String get transferSaved => 'Transfer created';

  @override
  String maxQtyAvailable(Object qty) {
    return 'Maximum available: $qty';
  }

  @override
  String get branchesMustDiffer => 'Choose two different branches';

  @override
  String get partId => 'Part ID';

  @override
  String transferRowTitle(Object id) {
    return 'Transfer $id';
  }

  @override
  String get quantity => 'Quantity';

  @override
  String get completeTransfer => 'Complete transfer';

  @override
  String get cancelTransfer => 'Cancel transfer';

  @override
  String get pendingSyncTitle => 'Pending sync';

  @override
  String get syncing => 'Syncingâ€¦';

  @override
  String get syncNow => 'Sync now';

  @override
  String get noPendingInvoices => 'No pending invoices';

  @override
  String pendingRowSubtitle(Object status, Object total, Object date) {
    return '$status Â· $total Â· $date';
  }

  @override
  String get salesReportTitle => 'Sales report';

  @override
  String get inventoryReportTitle => 'Inventory valuation';

  @override
  String get customersReportTitle => 'Customer balances';

  @override
  String get suppliersReportTitle => 'Supplier debt';

  @override
  String get returnsReportTitle => 'Returns summary';

  @override
  String get reportsHubTitle => 'Reports';

  @override
  String get reportsHubSubtitle =>
      'Choose a report to understand sales, stock, debts, and returns';

  @override
  String get backToReports => 'All reports';

  @override
  String get runReport => 'Run report';

  @override
  String get reportTapRun =>
      'Set the date range (if shown), then tap Run report';

  @override
  String reportDateRange(Object from, Object to) {
    return '$from to $to';
  }

  @override
  String reportRowCount(Object count) {
    return '$count rows';
  }

  @override
  String get reportDescSales =>
      'All sales invoices in the selected period â€” number, customer, payment type, and total.';

  @override
  String get reportDescInventory =>
      'Current stock value: quantity Ã— cost and Ã— sell price per part.';

  @override
  String get reportDescCustomers =>
      'Who owes you? Customer credit balances and oldest unpaid invoice date.';

  @override
  String get reportDescSuppliers =>
      'What you owe suppliers? Total debt per supplier.';

  @override
  String get reportDescReturns =>
      'Returns in the period: count, value, and reasons.';

  @override
  String get reportInvoiceCount => 'Invoice count';

  @override
  String get reportTotalSales => 'Total sales';

  @override
  String get reportReturnsCount => 'Return count';

  @override
  String get reportReturnsValue => 'Return value';

  @override
  String get reportByReason => 'By reason';

  @override
  String reportReasonCount(Object count) {
    return '$count times';
  }

  @override
  String get colInvoiceNumber => 'Invoice #';

  @override
  String get colCustomerName => 'Customer';

  @override
  String get colBranchName => 'Branch';

  @override
  String get colPaymentType => 'Payment';

  @override
  String get colTotal => 'Total';

  @override
  String get colSubtotal => 'Subtotal';

  @override
  String get colDiscount => 'Discount';

  @override
  String get colDate => 'Date';

  @override
  String get colValueCost => 'Value (cost)';

  @override
  String get colValueSell => 'Value (sell)';

  @override
  String get colOutstanding => 'Outstanding';

  @override
  String get colOldestInvoice => 'Oldest invoice';

  @override
  String get colTotalDebt => 'Total debt';

  @override
  String get colUpdatedAt => 'Updated';

  @override
  String get colCount => 'Count';

  @override
  String get editPart => 'Edit part';

  @override
  String get newPart => 'New part';

  @override
  String get code => 'Code';

  @override
  String get category => 'Category';

  @override
  String get unit => 'Unit';

  @override
  String get selectCategory => 'Select category';

  @override
  String get selectUnit => 'Select unit';

  @override
  String get categoryOtherHint => 'Category name (if not in list)';

  @override
  String get unitOtherHint => 'Unit name (if not in list)';

  @override
  String get fieldRequired => 'This field is required';

  @override
  String get partSaved => 'Part saved';

  @override
  String get partDeleted => 'Part deleted';

  @override
  String confirmDeletePart(Object name) {
    return 'Delete $name? This cannot be undone if the part has no sales history.';
  }

  @override
  String get partCreateNotAllowed => 'Only admins and managers can add parts';

  @override
  String get partAddOffline => 'Connect to the internet to add products.';

  @override
  String get partBranchRequired => 'Select a branch before adding a part';

  @override
  String get openingQuantity => 'Opening qty';

  @override
  String get partCodeDuplicate =>
      'Part code already exists â€” use another code';

  @override
  String get partFillCategoryUnit => 'Select category and unit from the list';

  @override
  String get partInvalidUnit => 'Invalid unit â€” pick from the list';

  @override
  String get failedLoadPartMeta =>
      'Could not load categories or units â€” check connection';

  @override
  String get partCategoriesTitle => 'Part categories';

  @override
  String get partCategoriesSubtitle =>
      'Create and manage spare-part categories';

  @override
  String get addCategory => 'Add category';

  @override
  String get editCategory => 'Edit category';

  @override
  String get categoryKey => 'Key';

  @override
  String get categoryKeyHint =>
      'Lowercase letters, digits, and underscores only';

  @override
  String get categoryKeyInvalid => 'Invalid key â€” use a-z, 0-9, and _';

  @override
  String get categoryName => 'Name';

  @override
  String get categoryActive => 'Active';

  @override
  String get sortOrder => 'Sort order';

  @override
  String get deactivateCategoryTitle => 'Deactivate category';

  @override
  String get deactivateCategoryConfirm =>
      'This hides the category from new parts. Continue?';

  @override
  String get deactivate => 'Deactivate';

  @override
  String get internetRequired => 'Internet connection required';

  @override
  String get partImage => 'Part image';

  @override
  String get choosePartImage => 'Choose image';

  @override
  String get removePartImage => 'Remove image';

  @override
  String get partImageTooLarge => 'Image exceeds 2 MB limit';

  @override
  String get partImageInvalidType =>
      'Unsupported file type â€” use JPG, PNG, or WebP only';

  @override
  String get unitPc => 'Piece';

  @override
  String get unitBox => 'Box';

  @override
  String get unitSet => 'Set';

  @override
  String get unitKg => 'Kilogram';

  @override
  String get unitM => 'Meter';

  @override
  String get unitL => 'Liter';

  @override
  String get unitRoll => 'Roll';

  @override
  String get unitPack => 'Pack';

  @override
  String get sellPrice => 'Sell price';

  @override
  String get costPrice => 'Cost price';

  @override
  String get minStock => 'Min stock';

  @override
  String partRowSubtitle(
    Object category,
    Object sell,
    Object cost,
    Object min,
  ) {
    return '$category · sell $sell · cost $cost · min $min';
  }

  @override
  String get adjustStock => 'Adjust stock';

  @override
  String get stockAdjusted => 'Stock updated';

  @override
  String get branchId => 'Branch ID';

  @override
  String get quantityDelta => 'Quantity delta';

  @override
  String get physicalCount => 'Physical count';

  @override
  String branchRowLabel(Object name) {
    return 'Branch: $name';
  }

  @override
  String qtyRowLabel(Object qty) {
    return 'Qty: $qty';
  }

  @override
  String get serverTab => 'Server';

  @override
  String get localPendingTab => 'Local pending';

  @override
  String invoiceDetailTitle(Object id) {
    return 'Invoice $id';
  }

  @override
  String paymentValue(Object type) {
    return 'Payment: $type';
  }

  @override
  String totalValue(Object amount) {
    return 'Total: $amount';
  }

  @override
  String quantityTimes(Object qty) {
    return 'Ã—$qty';
  }

  @override
  String invoiceRowSubtitle(Object payment, Object date) {
    return '$payment Â· $date';
  }

  @override
  String get statusPending => 'Pending';

  @override
  String get statusPaid => 'Paid';

  @override
  String get statusApproved => 'Approved';

  @override
  String get statusRejected => 'Rejected';

  @override
  String get statusCompleted => 'Completed';

  @override
  String get statusCancelled => 'Cancelled';

  @override
  String noStockForPart(Object code) {
    return 'No stock for $code';
  }

  @override
  String insufficientStockFor(Object code) {
    return 'Insufficient stock for $code';
  }

  @override
  String get insufficientStock => 'Insufficient stock';

  @override
  String get selectCustomerAndItems => 'Select a customer and add items';

  @override
  String get creditSalesBlockedOffline =>
      'Credit sales are not allowed while offline';

  @override
  String get creditSalesUnavailableOffline =>
      'Credit sales may be unavailable offline';

  @override
  String get productAnalysisTitle => 'Product analysis';

  @override
  String get productAnalysisSubtitle => 'Sales and stock per part';

  @override
  String get unitsSold => 'Units sold';

  @override
  String get revenue => 'Revenue';

  @override
  String get stockLevel => 'Stock';

  @override
  String get noProductData => 'No product sales data yet';

  @override
  String get viewAllProducts => 'View all parts';

  @override
  String get partAnalysisTitle => 'Part analysis';

  @override
  String get partAnalysisSubtitle =>
      'Stock, sales, purchases, returns, and movements';

  @override
  String get partAnalysisOnlineOnly =>
      'Part analysis requires an internet connection';

  @override
  String get salesPeriodTitle => 'Sales (period)';

  @override
  String get grossProfit => 'Gross profit';

  @override
  String get grossMargin => 'Gross margin';

  @override
  String get estimatedCogs => 'Est. COGS';

  @override
  String get valueAtCost => 'Stock value (cost)';

  @override
  String get valueAtSell => 'Stock value (sell)';

  @override
  String get marginPerUnit => 'Margin per unit';

  @override
  String get lowStockLabel => 'Below min?';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get salesByMonth => 'Sales by month';

  @override
  String get stockByBranch => 'Stock by branch';

  @override
  String get purchasesAndReturns => 'Purchases & returns';

  @override
  String get unitsPurchased => 'Units purchased';

  @override
  String get purchaseCost => 'Purchase cost';

  @override
  String get purchaseOrderCount => 'Purchase orders';

  @override
  String get unitsReturned => 'Units returned';

  @override
  String get returnsValue => 'Returns value';

  @override
  String get movementsByType => 'Movements summary';

  @override
  String get movementType => 'Movement type';

  @override
  String get recentMovements => 'Recent movements';

  @override
  String get createdBy => 'Created by';

  @override
  String get allBranches => 'All branches';

  @override
  String get movementPurchaseIn => 'Purchase in';

  @override
  String get movementSaleOut => 'Sale out';

  @override
  String get movementTransferIn => 'Transfer in';

  @override
  String get movementTransferOut => 'Transfer out';

  @override
  String get movementReturnIn => 'Return in';

  @override
  String get movementReturnOut => 'Return out';

  @override
  String get movementAdjustment => 'Adjustment';

  @override
  String get branchFinanceTitle => 'Branch finance';

  @override
  String get branchFinanceSubtitle =>
      'Inter-branch charges and payments from transfers';

  @override
  String get branchBalancesTab => 'Balances';

  @override
  String get branchLedgerTab => 'Ledger';

  @override
  String get recordBranchCharge => 'Record charge';

  @override
  String get recordBranchPayment => 'Record payment';

  @override
  String get branchChargeSaved => 'Charge recorded';

  @override
  String get branchPaymentSaved => 'Payment recorded';

  @override
  String get branchEntrySettled => 'Entry settled';

  @override
  String get creditorBranch => 'Creditor branch (owed to)';

  @override
  String get debtorBranch => 'Debtor branch (owes)';

  @override
  String get balanceOwed => 'Balance owed';

  @override
  String get totalCharges => 'Total charges';

  @override
  String get totalPayments => 'Total payments';

  @override
  String get openChargesCount => 'Open charges';

  @override
  String branchBalanceRow(Object debtor, Object creditor) {
    return '$debtor owes $creditor';
  }

  @override
  String branchLedgerRow(Object debtor, Object creditor, Object amount) {
    return '$debtor â†’ $creditor Â· $amount';
  }

  @override
  String get entryTypeCharge => 'Charge';

  @override
  String get entryTypePayment => 'Payment';

  @override
  String get statusOpen => 'Open';

  @override
  String get filterAll => 'All';

  @override
  String get markSettled => 'Mark settled';

  @override
  String get needTwoBranches => 'At least two branches are required';

  @override
  String get amount => 'Amount';

  @override
  String get completeTransferHint =>
      'Completing moves stock from source to destination. You can record an inter-branch charge.';

  @override
  String get transferValuation => 'Charge valuation';

  @override
  String get valuationCost => 'Cost price';

  @override
  String get valuationSell => 'Sell price';

  @override
  String get recordInterBranchCharge => 'Record inter-branch charge';

  @override
  String get recordBranchChargeHint =>
      'Creates a ledger entry: receiving branch owes sending branch for stock value';

  @override
  String get transferCompleted => 'Transfer completed';

  @override
  String get transferCompletedWithCharge =>
      'Transfer completed; inter-branch charge recorded';

  @override
  String get editTransfer => 'Edit transfer';

  @override
  String get transferEditPendingOnly => 'Only pending transfers can be edited.';

  @override
  String get transferUpdated => 'Transfer updated';

  @override
  String get editPayment => 'Edit payment';

  @override
  String get editPaymentHint =>
      'Only the most recent payment can be corrected.';

  @override
  String get paymentUpdated => 'Payment updated';

  @override
  String get partsSalesChartTitle => 'Parts sales chart';

  @override
  String get partsSalesChartSubtitle =>
      'Top-selling parts by month for the year';

  @override
  String dashboardPartsChartSubtitle(Object year) {
    return 'Top 5 parts by month during $year';
  }

  @override
  String get viewFullChart => 'Full report';

  @override
  String get reportDescPartsSalesChart =>
      'Monthly trend for top parts â€” by units or revenue.';

  @override
  String get year => 'Year';

  @override
  String get rankBy => 'Rank by';

  @override
  String get rankByUnits => 'Units';

  @override
  String get rankByRevenue => 'Revenue';

  @override
  String get limit => 'Limit';

  @override
  String topPartsYear(Object year) {
    return 'Top parts â€” $year';
  }

  @override
  String get financialReportTitle => 'Financial report (P&L)';

  @override
  String get reportDescFinancial =>
      'Revenue, discounts, refunds, gross profit, and net profit by period. Returns use approval date.';

  @override
  String get colRevenue => 'Revenue';

  @override
  String get colGrossProfit => 'Gross profit';

  @override
  String get financialReturnsSection => 'Returns in period';

  @override
  String get financialCustomerReturns => 'Customer returns';

  @override
  String get financialSupplierReturns => 'Supplier returns';

  @override
  String get financialByBranch => 'By branch';

  @override
  String get financialReturnsApprovalNote =>
      'Returns are counted by approval date (completed_at), not create date.';

  @override
  String get usersTitle => 'Users';

  @override
  String get usersSubtitle =>
      'Manage staff accounts, roles, and branch assignment (admin only).';

  @override
  String get newUser => 'New user';

  @override
  String get editUser => 'Edit user';

  @override
  String get userSaved => 'User saved';

  @override
  String get userDeactivated => 'User deactivated';

  @override
  String get deactivateUser => 'Deactivate user';

  @override
  String deactivateUserConfirm(Object name) {
    return 'Deactivate $name? They will no longer be able to sign in.';
  }

  @override
  String get role => 'Role';

  @override
  String get posSelectBranch => 'Select branch for this sale';

  @override
  String get posBranchRequiredHint =>
      'Choose a branch before adding items or completing a sale.';

  @override
  String get businessCapitalTitle => 'Business capital';

  @override
  String get businessCapitalSubtitleAdmin =>
      'Set owner funding used to compare stock and receivables against available cash.';

  @override
  String get businessCapitalSubtitleView =>
      'Financing overview (read-only). Contact an admin to change capital.';

  @override
  String get businessCapitalAmount => 'Owner capital';

  @override
  String get businessCapitalSet => 'Update capital';

  @override
  String get businessCapitalUpdateTitle => 'Update business capital';

  @override
  String get businessCapitalSaved => 'Business capital saved';

  @override
  String get businessCapitalDefaultReason => 'Capital adjustment';

  @override
  String get businessCapitalNotSet =>
      'Capital not configured yet. An admin can set it below.';

  @override
  String get businessCapitalHistory => 'Capital history';

  @override
  String get branchFilterAll => 'All branches';

  @override
  String get branchFilterLabel => 'Branch';

  @override
  String get branchFilterClear => 'Clear branch filter';

  @override
  String get withdrawFromProfit => 'Withdraw from profit';

  @override
  String get withdrawableProfit => 'Withdrawable profit';

  @override
  String get profitWithdrawnSuccess => 'Profit withdrawn';

  @override
  String get noWithdrawableProfit => 'No withdrawable profit available';

  @override
  String get ownerCashOutTitle => 'Owner cash out';

  @override
  String get ownerCashOutSubtitle =>
      'Withdraw realized profit. Business capital is not reduced.';

  @override
  String get ownerCashOutRecord => 'Cash out';

  @override
  String get ownerCashOutConfirm => 'Confirm';

  @override
  String get ownerCashOutAmount => 'Amount';

  @override
  String get ownerCashOutReason => 'Reason';

  @override
  String get ownerCashOutSuccess => 'Cash out recorded';

  @override
  String get ownerCashOutHistory => 'Cash out history';

  @override
  String ownerCashOutAmountInvalid(Object max) {
    return 'Amount must be between 0.01 and $max';
  }

  @override
  String get capitalInventoryAtCost => 'Inventory (at cost)';

  @override
  String get capitalCustomerReceivables => 'Customer receivables';

  @override
  String get capitalSupplierDebt => 'Supplier debt';

  @override
  String get capitalDeployed => 'Deployed capital';

  @override
  String get capitalEstimatedAvailable => 'Est. available cash';

  @override
  String get notes => 'Notes';

  @override
  String get invalidAmount => 'Enter a valid amount';

  @override
  String get weeklyDiscount => 'Weekly discounts';

  @override
  String get weeklyGrossProfit => 'Weekly gross profit';

  @override
  String get dashboardPurchasesTitle => 'Purchases & supplier debt';

  @override
  String get dashboardPurchasesSubtitle =>
      'POs, installments, and payments this week';

  @override
  String get totalSupplierDebt => 'Total supplier debt';

  @override
  String get unpaidInstallmentsTotal => 'Unpaid installments';

  @override
  String get unpaidInstallmentsCount => 'Unpaid installments';

  @override
  String get overdueInstallmentsTotal => 'Overdue installments';

  @override
  String get weeklySupplierPayments => 'Supplier payments (week)';

  @override
  String get weeklyPurchasesOrdered => 'Purchases ordered (week)';

  @override
  String get weeklyPurchasesReceived => 'Purchases received (week)';

  @override
  String get payablesOverdueInstallments => 'Overdue installments';

  @override
  String get payablesUpcomingInstallments => 'Upcoming installments';

  @override
  String get viewInstallments => 'View installments';

  @override
  String get averageCost => 'Average cost';

  @override
  String get catalogCostRollup => 'Weighted average cost';

  @override
  String get costFromPurchasesHint =>
      'Leave blank to use the current branch average.';

  @override
  String get catalogCostRollupHint =>
      'Catalog rollup — branch costs update from purchases and stock receipts.';

  @override
  String get adjustUnitCostOptional => 'Unit cost (optional)';
}
