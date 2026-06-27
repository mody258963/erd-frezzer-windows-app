import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Noor Al-Islam'**
  String get appTitle;

  /// No description provided for @appSubtitle.
  ///
  /// In en, this message translates to:
  /// **'ERB-Frezzer ERP'**
  String get appSubtitle;

  /// No description provided for @appTagline.
  ///
  /// In en, this message translates to:
  /// **'Inventory, sales, and branch operations\nin one desktop workspace.'**
  String get appTagline;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get welcomeBack;

  /// No description provided for @signInToContinue.
  ///
  /// In en, this message translates to:
  /// **'Sign in to continue'**
  String get signInToContinue;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @online.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get online;

  /// No description provided for @offline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get offline;

  /// No description provided for @offlineBanner.
  ///
  /// In en, this message translates to:
  /// **'Offline â€” only new sales can be saved locally'**
  String get offlineBanner;

  /// No description provided for @dismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get dismiss;

  /// No description provided for @sync.
  ///
  /// In en, this message translates to:
  /// **'Sync'**
  String get sync;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @branch.
  ///
  /// In en, this message translates to:
  /// **'Branch'**
  String get branch;

  /// No description provided for @user.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get user;

  /// No description provided for @navDashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get navDashboard;

  /// No description provided for @navPos.
  ///
  /// In en, this message translates to:
  /// **'POS'**
  String get navPos;

  /// No description provided for @navParts.
  ///
  /// In en, this message translates to:
  /// **'Parts'**
  String get navParts;

  /// No description provided for @navStock.
  ///
  /// In en, this message translates to:
  /// **'Stock'**
  String get navStock;

  /// No description provided for @navPartsStock.
  ///
  /// In en, this message translates to:
  /// **'Parts & stock'**
  String get navPartsStock;

  /// No description provided for @navCustomers.
  ///
  /// In en, this message translates to:
  /// **'Customers'**
  String get navCustomers;

  /// No description provided for @navSales.
  ///
  /// In en, this message translates to:
  /// **'Sales'**
  String get navSales;

  /// No description provided for @navSettle.
  ///
  /// In en, this message translates to:
  /// **'Settlements'**
  String get navSettle;

  /// No description provided for @navSupply.
  ///
  /// In en, this message translates to:
  /// **'Suppliers'**
  String get navSupply;

  /// No description provided for @navPurchases.
  ///
  /// In en, this message translates to:
  /// **'Purchases'**
  String get navPurchases;

  /// No description provided for @navReturns.
  ///
  /// In en, this message translates to:
  /// **'Returns'**
  String get navReturns;

  /// No description provided for @navReports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get navReports;

  /// No description provided for @navBranches.
  ///
  /// In en, this message translates to:
  /// **'Branches'**
  String get navBranches;

  /// No description provided for @navTransfers.
  ///
  /// In en, this message translates to:
  /// **'Transfers'**
  String get navTransfers;

  /// No description provided for @navBranchFinance.
  ///
  /// In en, this message translates to:
  /// **'Branch finance'**
  String get navBranchFinance;

  /// No description provided for @navInstallments.
  ///
  /// In en, this message translates to:
  /// **'Installments'**
  String get navInstallments;

  /// No description provided for @navPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get navPending;

  /// No description provided for @navLocalSales.
  ///
  /// In en, this message translates to:
  /// **'Local sales'**
  String get navLocalSales;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @dashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboardTitle;

  /// No description provided for @dashboardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your business at a glance â€” sales, stock, and money'**
  String get dashboardSubtitle;

  /// No description provided for @dashboardPeriodToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get dashboardPeriodToday;

  /// No description provided for @dashboardPeriodWeek.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get dashboardPeriodWeek;

  /// No description provided for @dashboardPeriodMonth.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get dashboardPeriodMonth;

  /// No description provided for @monthlyProfit.
  ///
  /// In en, this message translates to:
  /// **'Monthly profit'**
  String get monthlyProfit;

  /// No description provided for @dashboardNeedsAttention.
  ///
  /// In en, this message translates to:
  /// **'Needs attention'**
  String get dashboardNeedsAttention;

  /// No description provided for @dashboardAllClear.
  ///
  /// In en, this message translates to:
  /// **'All clear'**
  String get dashboardAllClear;

  /// No description provided for @activityLogTitle.
  ///
  /// In en, this message translates to:
  /// **'Activity log'**
  String get activityLogTitle;

  /// No description provided for @activityLogSubtitle.
  ///
  /// In en, this message translates to:
  /// **'What changed recently in your store'**
  String get activityLogSubtitle;

  /// No description provided for @activityInvoiceCreated.
  ///
  /// In en, this message translates to:
  /// **'New sale recorded'**
  String get activityInvoiceCreated;

  /// No description provided for @activityInvoiceUpdated.
  ///
  /// In en, this message translates to:
  /// **'Sale updated'**
  String get activityInvoiceUpdated;

  /// No description provided for @activityInvoiceCancelled.
  ///
  /// In en, this message translates to:
  /// **'Sale cancelled'**
  String get activityInvoiceCancelled;

  /// No description provided for @activityInventoryAdjusted.
  ///
  /// In en, this message translates to:
  /// **'Stock quantity adjusted'**
  String get activityInventoryAdjusted;

  /// No description provided for @activityPurchaseCreated.
  ///
  /// In en, this message translates to:
  /// **'Purchase order created'**
  String get activityPurchaseCreated;

  /// No description provided for @activityPurchaseReceived.
  ///
  /// In en, this message translates to:
  /// **'Purchase received into stock'**
  String get activityPurchaseReceived;

  /// No description provided for @activityCustomerCreated.
  ///
  /// In en, this message translates to:
  /// **'New customer added'**
  String get activityCustomerCreated;

  /// No description provided for @activityCustomerUpdated.
  ///
  /// In en, this message translates to:
  /// **'Customer updated'**
  String get activityCustomerUpdated;

  /// No description provided for @activitySettlementRecorded.
  ///
  /// In en, this message translates to:
  /// **'Customer payment recorded'**
  String get activitySettlementRecorded;

  /// No description provided for @activityTransferCreated.
  ///
  /// In en, this message translates to:
  /// **'Stock transfer created'**
  String get activityTransferCreated;

  /// No description provided for @activityTransferCompleted.
  ///
  /// In en, this message translates to:
  /// **'Stock transfer completed'**
  String get activityTransferCompleted;

  /// No description provided for @activityReturnApproved.
  ///
  /// In en, this message translates to:
  /// **'Product return approved'**
  String get activityReturnApproved;

  /// No description provided for @activityReturnRejected.
  ///
  /// In en, this message translates to:
  /// **'Product return rejected'**
  String get activityReturnRejected;

  /// No description provided for @activityPartCreated.
  ///
  /// In en, this message translates to:
  /// **'New part added to catalog'**
  String get activityPartCreated;

  /// No description provided for @activityPartUpdated.
  ///
  /// In en, this message translates to:
  /// **'Part information updated'**
  String get activityPartUpdated;

  /// No description provided for @activitySupplierCreated.
  ///
  /// In en, this message translates to:
  /// **'New supplier added'**
  String get activitySupplierCreated;

  /// No description provided for @activitySyncCompleted.
  ///
  /// In en, this message translates to:
  /// **'Data sync completed'**
  String get activitySyncCompleted;

  /// No description provided for @activityOwnerCashOut.
  ///
  /// In en, this message translates to:
  /// **'Owner cash out recorded'**
  String get activityOwnerCashOut;

  /// No description provided for @activityGeneric.
  ///
  /// In en, this message translates to:
  /// **'{action} Â· {entity}'**
  String activityGeneric(Object action, Object entity);

  /// No description provided for @entityInvoice.
  ///
  /// In en, this message translates to:
  /// **'Sales'**
  String get entityInvoice;

  /// No description provided for @entityStock.
  ///
  /// In en, this message translates to:
  /// **'Inventory'**
  String get entityStock;

  /// No description provided for @entityCustomer.
  ///
  /// In en, this message translates to:
  /// **'Customers'**
  String get entityCustomer;

  /// No description provided for @entityPurchase.
  ///
  /// In en, this message translates to:
  /// **'Purchases'**
  String get entityPurchase;

  /// No description provided for @entitySupplier.
  ///
  /// In en, this message translates to:
  /// **'Suppliers'**
  String get entitySupplier;

  /// No description provided for @entityPart.
  ///
  /// In en, this message translates to:
  /// **'Parts'**
  String get entityPart;

  /// No description provided for @entityTransfer.
  ///
  /// In en, this message translates to:
  /// **'Transfers'**
  String get entityTransfer;

  /// No description provided for @entityReturn.
  ///
  /// In en, this message translates to:
  /// **'Returns'**
  String get entityReturn;

  /// No description provided for @entitySettlement.
  ///
  /// In en, this message translates to:
  /// **'Settlements'**
  String get entitySettlement;

  /// No description provided for @entityBranch.
  ///
  /// In en, this message translates to:
  /// **'Branches'**
  String get entityBranch;

  /// No description provided for @noDebtors.
  ///
  /// In en, this message translates to:
  /// **'No outstanding customer balances'**
  String get noDebtors;

  /// No description provided for @noCreditors.
  ///
  /// In en, this message translates to:
  /// **'No outstanding supplier balances'**
  String get noCreditors;

  /// No description provided for @noStockAlerts.
  ///
  /// In en, this message translates to:
  /// **'Stock levels look healthy'**
  String get noStockAlerts;

  /// No description provided for @openPos.
  ///
  /// In en, this message translates to:
  /// **'Open POS'**
  String get openPos;

  /// No description provided for @viewInventory.
  ///
  /// In en, this message translates to:
  /// **'View inventory'**
  String get viewInventory;

  /// No description provided for @todaySales.
  ///
  /// In en, this message translates to:
  /// **'Today sales'**
  String get todaySales;

  /// No description provided for @todayProfit.
  ///
  /// In en, this message translates to:
  /// **'Today\'s profit'**
  String get todayProfit;

  /// No description provided for @weeklyProfit.
  ///
  /// In en, this message translates to:
  /// **'Weekly profit'**
  String get weeklyProfit;

  /// No description provided for @weeklyRevenue.
  ///
  /// In en, this message translates to:
  /// **'Weekly revenue'**
  String get weeklyRevenue;

  /// No description provided for @weeklyCost.
  ///
  /// In en, this message translates to:
  /// **'Weekly cost'**
  String get weeklyCost;

  /// No description provided for @profitAmount.
  ///
  /// In en, this message translates to:
  /// **'Profit'**
  String get profitAmount;

  /// No description provided for @todayCost.
  ///
  /// In en, this message translates to:
  /// **'Cost of goods (today)'**
  String get todayCost;

  /// No description provided for @todayInvoices.
  ///
  /// In en, this message translates to:
  /// **'Invoices today'**
  String get todayInvoices;

  /// No description provided for @todayProfitEstimated.
  ///
  /// In en, this message translates to:
  /// **'Calculated from today\'s sales and part costs'**
  String get todayProfitEstimated;

  /// No description provided for @profitMargin.
  ///
  /// In en, this message translates to:
  /// **'Margin: {percent}%'**
  String profitMargin(Object percent);

  /// No description provided for @lowStock.
  ///
  /// In en, this message translates to:
  /// **'Low stock'**
  String get lowStock;

  /// No description provided for @overdueInstallments.
  ///
  /// In en, this message translates to:
  /// **'Overdue installments'**
  String get overdueInstallments;

  /// No description provided for @pendingCredit.
  ///
  /// In en, this message translates to:
  /// **'Pending credit'**
  String get pendingCredit;

  /// No description provided for @salesTrend.
  ///
  /// In en, this message translates to:
  /// **'Sales trend'**
  String get salesTrend;

  /// No description provided for @recentActivity.
  ///
  /// In en, this message translates to:
  /// **'Recent activity'**
  String get recentActivity;

  /// No description provided for @noRecentActivity.
  ///
  /// In en, this message translates to:
  /// **'No recent activity'**
  String get noRecentActivity;

  /// No description provided for @loadingDashboard.
  ///
  /// In en, this message translates to:
  /// **'Loading dashboardâ€¦'**
  String get loadingDashboard;

  /// No description provided for @posTitle.
  ///
  /// In en, this message translates to:
  /// **'POS â€” New sale'**
  String get posTitle;

  /// No description provided for @posSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Search parts or scan a barcode to add to cart'**
  String get posSubtitle;

  /// No description provided for @printDaySales.
  ///
  /// In en, this message translates to:
  /// **'Print day sales'**
  String get printDaySales;

  /// No description provided for @printDaySalesReport.
  ///
  /// In en, this message translates to:
  /// **'Day sales report'**
  String get printDaySalesReport;

  /// No description provided for @noDaySales.
  ///
  /// In en, this message translates to:
  /// **'No sales today to print'**
  String get noDaySales;

  /// No description provided for @daySalesPrinted.
  ///
  /// In en, this message translates to:
  /// **'Day sales report sent to printer'**
  String get daySalesPrinted;

  /// No description provided for @searchScanBarcode.
  ///
  /// In en, this message translates to:
  /// **'Search / scan barcode'**
  String get searchScanBarcode;

  /// No description provided for @searchPartToAdd.
  ///
  /// In en, this message translates to:
  /// **'Search for a part to add'**
  String get searchPartToAdd;

  /// No description provided for @cart.
  ///
  /// In en, this message translates to:
  /// **'Cart'**
  String get cart;

  /// No description provided for @customer.
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get customer;

  /// No description provided for @cash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get cash;

  /// No description provided for @credit.
  ///
  /// In en, this message translates to:
  /// **'Credit'**
  String get credit;

  /// No description provided for @discount.
  ///
  /// In en, this message translates to:
  /// **'Discount'**
  String get discount;

  /// No description provided for @cartEmpty.
  ///
  /// In en, this message translates to:
  /// **'Cart is empty'**
  String get cartEmpty;

  /// No description provided for @removeFromCart.
  ///
  /// In en, this message translates to:
  /// **'Remove item'**
  String get removeFromCart;

  /// No description provided for @subtotal.
  ///
  /// In en, this message translates to:
  /// **'Subtotal'**
  String get subtotal;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @completeSale.
  ///
  /// In en, this message translates to:
  /// **'Complete sale'**
  String get completeSale;

  /// No description provided for @amountReceived.
  ///
  /// In en, this message translates to:
  /// **'Amount received'**
  String get amountReceived;

  /// No description provided for @changeDue.
  ///
  /// In en, this message translates to:
  /// **'Change due'**
  String get changeDue;

  /// No description provided for @amountReceivedTooLow.
  ///
  /// In en, this message translates to:
  /// **'Amount received must be at least the invoice total'**
  String get amountReceivedTooLow;

  /// No description provided for @processing.
  ///
  /// In en, this message translates to:
  /// **'Processingâ€¦'**
  String get processing;

  /// No description provided for @invalidLinePrice.
  ///
  /// In en, this message translates to:
  /// **'Enter a price greater than zero for each cart line'**
  String get invalidLinePrice;

  /// No description provided for @price.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get price;

  /// No description provided for @available.
  ///
  /// In en, this message translates to:
  /// **'Avail'**
  String get available;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Application preferences and sync'**
  String get settingsSubtitle;

  /// No description provided for @apiConnection.
  ///
  /// In en, this message translates to:
  /// **'API connection'**
  String get apiConnection;

  /// No description provided for @apiHostHint.
  ///
  /// In en, this message translates to:
  /// **'Host only â€” /api/v1 is appended automatically'**
  String get apiHostHint;

  /// No description provided for @apiBaseUrl.
  ///
  /// In en, this message translates to:
  /// **'API base URL'**
  String get apiBaseUrl;

  /// No description provided for @apiBaseUrlHint.
  ///
  /// In en, this message translates to:
  /// **'Server host only — do not include /api/v1'**
  String get apiBaseUrlHint;

  /// No description provided for @apiBaseUrlSaved.
  ///
  /// In en, this message translates to:
  /// **'API URL saved — checking connection…'**
  String get apiBaseUrlSaved;

  /// No description provided for @offlineCashOnly.
  ///
  /// In en, this message translates to:
  /// **'Offline cash-only'**
  String get offlineCashOnly;

  /// No description provided for @offlineCashOnlyHint.
  ///
  /// In en, this message translates to:
  /// **'Block credit payments when offline'**
  String get offlineCashOnlyHint;

  /// No description provided for @lastCatalogSync.
  ///
  /// In en, this message translates to:
  /// **'Last catalog sync'**
  String get lastCatalogSync;

  /// No description provided for @never.
  ///
  /// In en, this message translates to:
  /// **'Never'**
  String get never;

  /// No description provided for @saveSettings.
  ///
  /// In en, this message translates to:
  /// **'Save settings'**
  String get saveSettings;

  /// No description provided for @settingsSaved.
  ///
  /// In en, this message translates to:
  /// **'Settings saved'**
  String get settingsSaved;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageArabic.
  ///
  /// In en, this message translates to:
  /// **'Arabic'**
  String get languageArabic;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @printerSettings.
  ///
  /// In en, this message translates to:
  /// **'Printer settings'**
  String get printerSettings;

  /// No description provided for @openPrinterSettings.
  ///
  /// In en, this message translates to:
  /// **'Configure printer'**
  String get openPrinterSettings;

  /// No description provided for @customersTitle.
  ///
  /// In en, this message translates to:
  /// **'Customers'**
  String get customersTitle;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @newCustomer.
  ///
  /// In en, this message translates to:
  /// **'New customer'**
  String get newCustomer;

  /// No description provided for @customerBranchRequired.
  ///
  /// In en, this message translates to:
  /// **'Select a branch before adding a customer'**
  String get customerBranchRequired;

  /// No description provided for @inventoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Inventory'**
  String get inventoryTitle;

  /// No description provided for @lowStockFilter.
  ///
  /// In en, this message translates to:
  /// **'Low stock'**
  String get lowStockFilter;

  /// No description provided for @adjust.
  ///
  /// In en, this message translates to:
  /// **'Adjust'**
  String get adjust;

  /// No description provided for @receipt.
  ///
  /// In en, this message translates to:
  /// **'Receipt'**
  String get receipt;

  /// No description provided for @receiptPending.
  ///
  /// In en, this message translates to:
  /// **'Receipt (Pending sync)'**
  String get receiptPending;

  /// No description provided for @newSale.
  ///
  /// In en, this message translates to:
  /// **'New sale'**
  String get newSale;

  /// No description provided for @printReceipt.
  ///
  /// In en, this message translates to:
  /// **'Print receipt'**
  String get printReceipt;

  /// No description provided for @printing.
  ///
  /// In en, this message translates to:
  /// **'Printingâ€¦'**
  String get printing;

  /// No description provided for @printSuccess.
  ///
  /// In en, this message translates to:
  /// **'Receipt sent to printer'**
  String get printSuccess;

  /// No description provided for @printFailed.
  ///
  /// In en, this message translates to:
  /// **'Print failed: {error}'**
  String printFailed(String error);

  /// No description provided for @somethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get somethingWentWrong;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @nothingHereYet.
  ///
  /// In en, this message translates to:
  /// **'Nothing here yet'**
  String get nothingHereYet;

  /// No description provided for @printerDiscovery.
  ///
  /// In en, this message translates to:
  /// **'Discover printers'**
  String get printerDiscovery;

  /// No description provided for @printerRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh list'**
  String get printerRefresh;

  /// No description provided for @printerSelect.
  ///
  /// In en, this message translates to:
  /// **'Select printer'**
  String get printerSelect;

  /// No description provided for @printerConnect.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get printerConnect;

  /// No description provided for @printerDisconnect.
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get printerDisconnect;

  /// No description provided for @printerConnected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get printerConnected;

  /// No description provided for @printerDisconnected.
  ///
  /// In en, this message translates to:
  /// **'Disconnected'**
  String get printerDisconnected;

  /// No description provided for @printerNotConnected.
  ///
  /// In en, this message translates to:
  /// **'Printer not connected'**
  String get printerNotConnected;

  /// No description provided for @paperWidth.
  ///
  /// In en, this message translates to:
  /// **'Paper width'**
  String get paperWidth;

  /// No description provided for @paperWidth58.
  ///
  /// In en, this message translates to:
  /// **'58 mm'**
  String get paperWidth58;

  /// No description provided for @paperWidth80.
  ///
  /// In en, this message translates to:
  /// **'80 mm'**
  String get paperWidth80;

  /// No description provided for @companyName.
  ///
  /// In en, this message translates to:
  /// **'Company name'**
  String get companyName;

  /// No description provided for @footerText.
  ///
  /// In en, this message translates to:
  /// **'Footer'**
  String get footerText;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get phoneNumber;

  /// No description provided for @printTestPage.
  ///
  /// In en, this message translates to:
  /// **'Print test page'**
  String get printTestPage;

  /// No description provided for @savePrinterSettings.
  ///
  /// In en, this message translates to:
  /// **'Save printer settings'**
  String get savePrinterSettings;

  /// No description provided for @printerSettingsSaved.
  ///
  /// In en, this message translates to:
  /// **'Printer settings saved'**
  String get printerSettingsSaved;

  /// No description provided for @noPrintersFound.
  ///
  /// In en, this message translates to:
  /// **'No printers found'**
  String get noPrintersFound;

  /// No description provided for @autoPrintOnSale.
  ///
  /// In en, this message translates to:
  /// **'Auto-print after sale'**
  String get autoPrintOnSale;

  /// No description provided for @currencyEgp.
  ///
  /// In en, this message translates to:
  /// **'EGP'**
  String get currencyEgp;

  /// No description provided for @invoiceNumber.
  ///
  /// In en, this message translates to:
  /// **'Invoice #'**
  String get invoiceNumber;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @items.
  ///
  /// In en, this message translates to:
  /// **'Items'**
  String get items;

  /// No description provided for @payment.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get payment;

  /// No description provided for @partsTitle.
  ///
  /// In en, this message translates to:
  /// **'Parts'**
  String get partsTitle;

  /// No description provided for @invoicesTitle.
  ///
  /// In en, this message translates to:
  /// **'Sales'**
  String get invoicesTitle;

  /// No description provided for @localSalesTitle.
  ///
  /// In en, this message translates to:
  /// **'Local sales'**
  String get localSalesTitle;

  /// No description provided for @suppliersTitle.
  ///
  /// In en, this message translates to:
  /// **'Suppliers'**
  String get suppliersTitle;

  /// No description provided for @suppliersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Suppliers registered in the selected branch only'**
  String get suppliersSubtitle;

  /// No description provided for @supplierBranchRequired.
  ///
  /// In en, this message translates to:
  /// **'Select a branch before adding a supplier'**
  String get supplierBranchRequired;

  /// No description provided for @supplierBranchPoHint.
  ///
  /// In en, this message translates to:
  /// **'No suppliers in this branch yet'**
  String get supplierBranchPoHint;

  /// No description provided for @newSupplier.
  ///
  /// In en, this message translates to:
  /// **'New supplier'**
  String get newSupplier;

  /// No description provided for @editSupplier.
  ///
  /// In en, this message translates to:
  /// **'Edit supplier'**
  String get editSupplier;

  /// No description provided for @supplierName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get supplierName;

  /// No description provided for @supplierAddress.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get supplierAddress;

  /// No description provided for @supplierEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get supplierEmail;

  /// No description provided for @supplierDebt.
  ///
  /// In en, this message translates to:
  /// **'Outstanding debt'**
  String get supplierDebt;

  /// No description provided for @supplierUnpaidInstallments.
  ///
  /// In en, this message translates to:
  /// **'Unpaid installments'**
  String get supplierUnpaidInstallments;

  /// No description provided for @viewAllInstallments.
  ///
  /// In en, this message translates to:
  /// **'View all installments'**
  String get viewAllInstallments;

  /// No description provided for @supplierPayablesTitle.
  ///
  /// In en, this message translates to:
  /// **'Supplier payables'**
  String get supplierPayablesTitle;

  /// No description provided for @supplierPayablesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'One section per supplier — pay against total debt'**
  String get supplierPayablesSubtitle;

  /// No description provided for @paySupplierTitle.
  ///
  /// In en, this message translates to:
  /// **'Pay supplier'**
  String get paySupplierTitle;

  /// No description provided for @supplierPaidSuccess.
  ///
  /// In en, this message translates to:
  /// **'Supplier payment recorded.'**
  String get supplierPaidSuccess;

  /// No description provided for @supplierNoDebt.
  ///
  /// In en, this message translates to:
  /// **'No outstanding debt for this supplier.'**
  String get supplierNoDebt;

  /// No description provided for @supplierPayAmountInvalid.
  ///
  /// In en, this message translates to:
  /// **'Amount must be between 0.01 and {max}'**
  String supplierPayAmountInvalid(Object max);

  /// No description provided for @payInstallmentLegacy.
  ///
  /// In en, this message translates to:
  /// **'Pay installment'**
  String get payInstallmentLegacy;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @nameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name is required'**
  String get nameRequired;

  /// No description provided for @supplierSaved.
  ///
  /// In en, this message translates to:
  /// **'Supplier saved'**
  String get supplierSaved;

  /// No description provided for @supplierDeleted.
  ///
  /// In en, this message translates to:
  /// **'Supplier deleted'**
  String get supplierDeleted;

  /// No description provided for @contactPerson.
  ///
  /// In en, this message translates to:
  /// **'Contact person'**
  String get contactPerson;

  /// No description provided for @purchasesTitle.
  ///
  /// In en, this message translates to:
  /// **'Purchase orders'**
  String get purchasesTitle;

  /// No description provided for @newPurchase.
  ///
  /// In en, this message translates to:
  /// **'New purchase'**
  String get newPurchase;

  /// No description provided for @purchaseOrder.
  ///
  /// In en, this message translates to:
  /// **'PO'**
  String get purchaseOrder;

  /// No description provided for @purchaseSaved.
  ///
  /// In en, this message translates to:
  /// **'Purchase order created'**
  String get purchaseSaved;

  /// No description provided for @supplier.
  ///
  /// In en, this message translates to:
  /// **'Supplier'**
  String get supplier;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @paymentImmediate.
  ///
  /// In en, this message translates to:
  /// **'Immediate'**
  String get paymentImmediate;

  /// No description provided for @paymentInstallments.
  ///
  /// In en, this message translates to:
  /// **'Installments'**
  String get paymentInstallments;

  /// No description provided for @installmentCount.
  ///
  /// In en, this message translates to:
  /// **'Installment count'**
  String get installmentCount;

  /// No description provided for @installmentStartDate.
  ///
  /// In en, this message translates to:
  /// **'First installment date'**
  String get installmentStartDate;

  /// No description provided for @lineItems.
  ///
  /// In en, this message translates to:
  /// **'Line items'**
  String get lineItems;

  /// No description provided for @part.
  ///
  /// In en, this message translates to:
  /// **'Part'**
  String get part;

  /// No description provided for @qty.
  ///
  /// In en, this message translates to:
  /// **'Qty'**
  String get qty;

  /// No description provided for @unitCost.
  ///
  /// In en, this message translates to:
  /// **'Unit cost'**
  String get unitCost;

  /// No description provided for @addLine.
  ///
  /// In en, this message translates to:
  /// **'Add line'**
  String get addLine;

  /// No description provided for @receive.
  ///
  /// In en, this message translates to:
  /// **'Receive'**
  String get receive;

  /// No description provided for @noSuppliersHint.
  ///
  /// In en, this message translates to:
  /// **'Create a supplier first'**
  String get noSuppliersHint;

  /// No description provided for @branchRequired.
  ///
  /// In en, this message translates to:
  /// **'Your user must have a branch assigned'**
  String get branchRequired;

  /// No description provided for @addAtLeastOneLine.
  ///
  /// In en, this message translates to:
  /// **'Add at least one line item'**
  String get addAtLeastOneLine;

  /// No description provided for @receivablesTitle.
  ///
  /// In en, this message translates to:
  /// **'Receivables (customers)'**
  String get receivablesTitle;

  /// No description provided for @payablesTitle.
  ///
  /// In en, this message translates to:
  /// **'Payables (suppliers)'**
  String get payablesTitle;

  /// No description provided for @inventoryAlertsTitle.
  ///
  /// In en, this message translates to:
  /// **'Inventory alerts'**
  String get inventoryAlertsTitle;

  /// No description provided for @totalReceivable.
  ///
  /// In en, this message translates to:
  /// **'Total receivable'**
  String get totalReceivable;

  /// No description provided for @totalPayable.
  ///
  /// In en, this message translates to:
  /// **'Total payable'**
  String get totalPayable;

  /// No description provided for @topDebtors.
  ///
  /// In en, this message translates to:
  /// **'Top debtors'**
  String get topDebtors;

  /// No description provided for @topCreditors.
  ///
  /// In en, this message translates to:
  /// **'Top creditors'**
  String get topCreditors;

  /// No description provided for @configurePrinterFirst.
  ///
  /// In en, this message translates to:
  /// **'Configure printer in Settings first'**
  String get configurePrinterFirst;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @inactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get inactive;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @newAction.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get newAction;

  /// No description provided for @noData.
  ///
  /// In en, this message translates to:
  /// **'No data'**
  String get noData;

  /// No description provided for @balance.
  ///
  /// In en, this message translates to:
  /// **'Balance'**
  String get balance;

  /// No description provided for @balanceValue.
  ///
  /// In en, this message translates to:
  /// **'Balance: {amount}'**
  String balanceValue(Object amount);

  /// No description provided for @editCustomer.
  ///
  /// In en, this message translates to:
  /// **'Edit customer'**
  String get editCustomer;

  /// No description provided for @customerType.
  ///
  /// In en, this message translates to:
  /// **'Customer type'**
  String get customerType;

  /// No description provided for @creditLimit.
  ///
  /// In en, this message translates to:
  /// **'Credit limit'**
  String get creditLimit;

  /// No description provided for @customerRowSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{type} Â· {balance}'**
  String customerRowSubtitle(Object type, Object balance);

  /// No description provided for @customerSaved.
  ///
  /// In en, this message translates to:
  /// **'Customer saved'**
  String get customerSaved;

  /// No description provided for @contactInfo.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get contactInfo;

  /// No description provided for @purchaseHistory.
  ///
  /// In en, this message translates to:
  /// **'Purchase history'**
  String get purchaseHistory;

  /// No description provided for @purchaseHistoryHint.
  ///
  /// In en, this message translates to:
  /// **'Parts this customer bought â€” when and at which branch.'**
  String get purchaseHistoryHint;

  /// No description provided for @noPurchaseHistory.
  ///
  /// In en, this message translates to:
  /// **'No purchases recorded for this customer yet.'**
  String get noPurchaseHistory;

  /// No description provided for @totalPurchases.
  ///
  /// In en, this message translates to:
  /// **'Total purchases'**
  String get totalPurchases;

  /// No description provided for @tapRowForInvoice.
  ///
  /// In en, this message translates to:
  /// **'Tap a row to open the full invoice.'**
  String get tapRowForInvoice;

  /// No description provided for @customerViewThisWeek.
  ///
  /// In en, this message translates to:
  /// **'This week (Mon 9 AM – Sat)'**
  String get customerViewThisWeek;

  /// No description provided for @customerViewHistory.
  ///
  /// In en, this message translates to:
  /// **'Settled / history'**
  String get customerViewHistory;

  /// No description provided for @customerThisWeekHint.
  ///
  /// In en, this message translates to:
  /// **'Open work for {range} â€” unsettled invoices only.'**
  String customerThisWeekHint(Object range);

  /// No description provided for @customerHistoryHint.
  ///
  /// In en, this message translates to:
  /// **'Settled invoices and purchases from earlier weeks.'**
  String get customerHistoryHint;

  /// No description provided for @customerOpenWork.
  ///
  /// In en, this message translates to:
  /// **'This week\'s work'**
  String get customerOpenWork;

  /// No description provided for @customerSettledHistory.
  ///
  /// In en, this message translates to:
  /// **'Settled & history'**
  String get customerSettledHistory;

  /// No description provided for @customerSettledHistoryHint.
  ///
  /// In en, this message translates to:
  /// **'Invoices paid via settlement or from before this week.'**
  String get customerSettledHistoryHint;

  /// No description provided for @customerNoOpenWorkThisWeek.
  ///
  /// In en, this message translates to:
  /// **'No open invoices this week â€” all settled or none sold yet.'**
  String get customerNoOpenWorkThisWeek;

  /// No description provided for @customerNoSettledHistory.
  ///
  /// In en, this message translates to:
  /// **'No settled or older invoices yet.'**
  String get customerNoSettledHistory;

  /// No description provided for @customerWeekRange.
  ///
  /// In en, this message translates to:
  /// **'{from} â€“ {to}'**
  String customerWeekRange(Object from, Object to);

  /// No description provided for @customerNoWeekInvoices.
  ///
  /// In en, this message translates to:
  /// **'No invoices this week to print.'**
  String get customerNoWeekInvoices;

  /// No description provided for @printWeekInvoices.
  ///
  /// In en, this message translates to:
  /// **'Print week statement'**
  String get printWeekInvoices;

  /// No description provided for @printWeekInvoicesDetailed.
  ///
  /// In en, this message translates to:
  /// **'Print each invoice'**
  String get printWeekInvoicesDetailed;

  /// No description provided for @weekStatementPrinted.
  ///
  /// In en, this message translates to:
  /// **'Week statement sent to printer'**
  String get weekStatementPrinted;

  /// No description provided for @weekInvoicesPrinted.
  ///
  /// In en, this message translates to:
  /// **'Printed {count} invoice(s)'**
  String weekInvoicesPrinted(Object count);

  /// No description provided for @settled.
  ///
  /// In en, this message translates to:
  /// **'Settled'**
  String get settled;

  /// No description provided for @reportThisWeek.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get reportThisWeek;

  /// No description provided for @collectPaymentTitle.
  ///
  /// In en, this message translates to:
  /// **'Collect payment'**
  String get collectPaymentTitle;

  /// No description provided for @collectPaymentConfirm.
  ///
  /// In en, this message translates to:
  /// **'Collect'**
  String get collectPaymentConfirm;

  /// No description provided for @collectPaymentSuccess.
  ///
  /// In en, this message translates to:
  /// **'Payment recorded'**
  String get collectPaymentSuccess;

  /// No description provided for @customerNoBalanceDue.
  ///
  /// In en, this message translates to:
  /// **'No balance due'**
  String get customerNoBalanceDue;

  /// No description provided for @customerPayAmountInvalid.
  ///
  /// In en, this message translates to:
  /// **'Amount must be between 0.01 and {max}'**
  String customerPayAmountInvalid(Object max);

  /// No description provided for @customerPaymentHistory.
  ///
  /// In en, this message translates to:
  /// **'Payment history'**
  String get customerPaymentHistory;

  /// No description provided for @unpaidInvoicesTitle.
  ///
  /// In en, this message translates to:
  /// **'Unpaid invoices'**
  String get unpaidInvoicesTitle;

  /// No description provided for @unpaidInvoicesHint.
  ///
  /// In en, this message translates to:
  /// **'Partial payments apply to oldest invoices first.'**
  String get unpaidInvoicesHint;

  /// No description provided for @invoiceBalanceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Paid {paid} Â· Due {due}'**
  String invoiceBalanceSubtitle(Object paid, Object due);

  /// No description provided for @refundProfitImpact.
  ///
  /// In en, this message translates to:
  /// **'Return margin impact'**
  String get refundProfitImpact;

  /// No description provided for @linkToSupplier.
  ///
  /// In en, this message translates to:
  /// **'Link to supplier'**
  String get linkToSupplier;

  /// No description provided for @noLinkedSupplier.
  ///
  /// In en, this message translates to:
  /// **'No linked supplier'**
  String get noLinkedSupplier;

  /// No description provided for @linkedBalanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Net balance (linked)'**
  String get linkedBalanceTitle;

  /// No description provided for @linkedNotLinkedHint.
  ///
  /// In en, this message translates to:
  /// **'Link this customer to a supplier to see net balance and offset.'**
  String get linkedNotLinkedHint;

  /// No description provided for @linkedToSupplier.
  ///
  /// In en, this message translates to:
  /// **'Linked supplier: {name}'**
  String linkedToSupplier(Object name);

  /// No description provided for @linkedToCustomer.
  ///
  /// In en, this message translates to:
  /// **'Linked customer: {name}'**
  String linkedToCustomer(Object name);

  /// No description provided for @linkedCustomerReceivable.
  ///
  /// In en, this message translates to:
  /// **'They owe you'**
  String get linkedCustomerReceivable;

  /// No description provided for @linkedSupplierPayable.
  ///
  /// In en, this message translates to:
  /// **'You owe them'**
  String get linkedSupplierPayable;

  /// No description provided for @linkedNetBalance.
  ///
  /// In en, this message translates to:
  /// **'Net balance'**
  String get linkedNetBalance;

  /// No description provided for @netTheyOweUs.
  ///
  /// In en, this message translates to:
  /// **'For us {amount}'**
  String netTheyOweUs(Object amount);

  /// No description provided for @netWeOweThem.
  ///
  /// In en, this message translates to:
  /// **'On us {amount}'**
  String netWeOweThem(Object amount);

  /// No description provided for @netBalanced.
  ///
  /// In en, this message translates to:
  /// **'Balanced'**
  String get netBalanced;

  /// No description provided for @offsetSupplierTitle.
  ///
  /// In en, this message translates to:
  /// **'Offset / contra settlement'**
  String get offsetSupplierTitle;

  /// No description provided for @offsetSupplierAction.
  ///
  /// In en, this message translates to:
  /// **'Offset (Ù…Ù‚Ø§ØµØ©)'**
  String get offsetSupplierAction;

  /// No description provided for @offsetAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Offset amount'**
  String get offsetAmountLabel;

  /// No description provided for @offsetFullAmount.
  ///
  /// In en, this message translates to:
  /// **'Offset full {amount}'**
  String offsetFullAmount(Object amount);

  /// No description provided for @offsetAmountInvalid.
  ///
  /// In en, this message translates to:
  /// **'Amount must be between 0.01 and {max}'**
  String offsetAmountInvalid(Object max);

  /// No description provided for @offsetNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Nothing to offset'**
  String get offsetNotAvailable;

  /// No description provided for @offsetConfirm.
  ///
  /// In en, this message translates to:
  /// **'Offset'**
  String get offsetConfirm;

  /// No description provided for @offsetSuccess.
  ///
  /// In en, this message translates to:
  /// **'Offset recorded'**
  String get offsetSuccess;

  /// No description provided for @purchaseAlreadyReceived.
  ///
  /// In en, this message translates to:
  /// **'This order was already received.'**
  String get purchaseAlreadyReceived;

  /// No description provided for @installmentAlreadyPaid.
  ///
  /// In en, this message translates to:
  /// **'Installment already paid.'**
  String get installmentAlreadyPaid;

  /// No description provided for @installmentPaidSuccess.
  ///
  /// In en, this message translates to:
  /// **'Installment paid.'**
  String get installmentPaidSuccess;

  /// No description provided for @payInstallmentTitle.
  ///
  /// In en, this message translates to:
  /// **'Pay installment #{no}'**
  String payInstallmentTitle(Object no);

  /// No description provided for @payInstallmentTitleGeneric.
  ///
  /// In en, this message translates to:
  /// **'Pay installment'**
  String get payInstallmentTitleGeneric;

  /// No description provided for @installmentScheduled.
  ///
  /// In en, this message translates to:
  /// **'Scheduled'**
  String get installmentScheduled;

  /// No description provided for @installmentAlreadyPaidAmount.
  ///
  /// In en, this message translates to:
  /// **'Already paid'**
  String get installmentAlreadyPaidAmount;

  /// No description provided for @installmentBalanceDue.
  ///
  /// In en, this message translates to:
  /// **'Balance due'**
  String get installmentBalanceDue;

  /// No description provided for @payAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Pay amount'**
  String get payAmountLabel;

  /// No description provided for @payFullBalance.
  ///
  /// In en, this message translates to:
  /// **'Pay full balance ({amount})'**
  String payFullBalance(Object amount);

  /// No description provided for @installmentPayAmountInvalid.
  ///
  /// In en, this message translates to:
  /// **'Amount must be between 0.01 and {max}'**
  String installmentPayAmountInvalid(Object max);

  /// No description provided for @returnResolution.
  ///
  /// In en, this message translates to:
  /// **'Resolution'**
  String get returnResolution;

  /// No description provided for @resolutionRestock.
  ///
  /// In en, this message translates to:
  /// **'Restock inventory'**
  String get resolutionRestock;

  /// No description provided for @resolutionCreditNote.
  ///
  /// In en, this message translates to:
  /// **'Credit note (reduce customer balance)'**
  String get resolutionCreditNote;

  /// No description provided for @resolutionRefundCash.
  ///
  /// In en, this message translates to:
  /// **'Refund cash'**
  String get resolutionRefundCash;

  /// No description provided for @resolutionReplace.
  ///
  /// In en, this message translates to:
  /// **'Replace item'**
  String get resolutionReplace;

  /// No description provided for @resolutionWriteoff.
  ///
  /// In en, this message translates to:
  /// **'Write off (no restock)'**
  String get resolutionWriteoff;

  /// No description provided for @resolutionSupplierCredit.
  ///
  /// In en, this message translates to:
  /// **'Supplier credit (reduce payables)'**
  String get resolutionSupplierCredit;

  /// No description provided for @returnDefectiveHint.
  ///
  /// In en, this message translates to:
  /// **'Defective items are not restocked. Use Write off or Refund cash so the customer gets their money back.'**
  String get returnDefectiveHint;

  /// No description provided for @returnLinesSummary.
  ///
  /// In en, this message translates to:
  /// **'Return lines'**
  String get returnLinesSummary;

  /// No description provided for @returnApprovedRefresh.
  ///
  /// In en, this message translates to:
  /// **'Return approved. Inventory and dashboard will refresh.'**
  String get returnApprovedRefresh;

  /// No description provided for @resolutionHintRestockOnly.
  ///
  /// In en, this message translates to:
  /// **'Stock increases at the branch. No cash refund on the dashboard.'**
  String get resolutionHintRestockOnly;

  /// No description provided for @resolutionHintRefundOnly.
  ///
  /// In en, this message translates to:
  /// **'Customer refund is deducted from dashboard totals.'**
  String get resolutionHintRefundOnly;

  /// No description provided for @resolutionHintRestockAndRefund.
  ///
  /// In en, this message translates to:
  /// **'Stock increases and customer refund applies (cash / credit note).'**
  String get resolutionHintRestockAndRefund;

  /// No description provided for @resolutionHintWriteoffDefective.
  ///
  /// In en, this message translates to:
  /// **'Defective: no restock. Customer receives refund (unit price Ã— qty).'**
  String get resolutionHintWriteoffDefective;

  /// No description provided for @resolutionHintReplace.
  ///
  /// In en, this message translates to:
  /// **'Replacement â€” no automatic stock or refund in this resolution.'**
  String get resolutionHintReplace;

  /// No description provided for @weeklyCustomerRefunds.
  ///
  /// In en, this message translates to:
  /// **'Weekly customer refunds'**
  String get weeklyCustomerRefunds;

  /// No description provided for @weeklyNetSales.
  ///
  /// In en, this message translates to:
  /// **'Weekly net sales'**
  String get weeklyNetSales;

  /// No description provided for @invoiceReturnStatusReturned.
  ///
  /// In en, this message translates to:
  /// **'Fully returned'**
  String get invoiceReturnStatusReturned;

  /// No description provided for @invoiceReturnStatusPartial.
  ///
  /// In en, this message translates to:
  /// **'Partial return'**
  String get invoiceReturnStatusPartial;

  /// No description provided for @quantitySold.
  ///
  /// In en, this message translates to:
  /// **'Sold'**
  String get quantitySold;

  /// No description provided for @quantityAvailableForReturn.
  ///
  /// In en, this message translates to:
  /// **'Available to return'**
  String get quantityAvailableForReturn;

  /// No description provided for @quantityReturned.
  ///
  /// In en, this message translates to:
  /// **'Returned'**
  String get quantityReturned;

  /// No description provided for @quantityRemaining.
  ///
  /// In en, this message translates to:
  /// **'Remaining'**
  String get quantityRemaining;

  /// No description provided for @returnRefundTotal.
  ///
  /// In en, this message translates to:
  /// **'Refund total'**
  String get returnRefundTotal;

  /// No description provided for @reprintInvoice.
  ///
  /// In en, this message translates to:
  /// **'Reprint invoice'**
  String get reprintInvoice;

  /// No description provided for @returnItemsTitle.
  ///
  /// In en, this message translates to:
  /// **'Return items'**
  String get returnItemsTitle;

  /// No description provided for @returnQuantityExceeded.
  ///
  /// In en, this message translates to:
  /// **'You can only return {available} more of this item.'**
  String returnQuantityExceeded(Object available);

  /// No description provided for @returnsOnInvoice.
  ///
  /// In en, this message translates to:
  /// **'Returns on this invoice'**
  String get returnsOnInvoice;

  /// No description provided for @netAfterReturns.
  ///
  /// In en, this message translates to:
  /// **'Net after returns'**
  String get netAfterReturns;

  /// No description provided for @originalTotal.
  ///
  /// In en, this message translates to:
  /// **'Original total'**
  String get originalTotal;

  /// No description provided for @returnedCompleted.
  ///
  /// In en, this message translates to:
  /// **'Returned (completed)'**
  String get returnedCompleted;

  /// No description provided for @soldQtyLabel.
  ///
  /// In en, this message translates to:
  /// **'Sold {qty}'**
  String soldQtyLabel(Object qty);

  /// No description provided for @availableQtyLabel.
  ///
  /// In en, this message translates to:
  /// **'Available: {qty}'**
  String availableQtyLabel(Object qty);

  /// No description provided for @returnedQtyLabel.
  ///
  /// In en, this message translates to:
  /// **'Returned: {completed} (pending {pending})'**
  String returnedQtyLabel(Object completed, Object pending);

  /// No description provided for @invoiceAlreadyReturned.
  ///
  /// In en, this message translates to:
  /// **'This invoice was already returned. Choose another invoice.'**
  String get invoiceAlreadyReturned;

  /// No description provided for @invoiceReturnStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Return status: {status}'**
  String invoiceReturnStatusLabel(Object status);

  /// No description provided for @noInvoicesAvailableForReturn.
  ///
  /// In en, this message translates to:
  /// **'No invoices available for return (all returned or cancelled).'**
  String get noInvoicesAvailableForReturn;

  /// No description provided for @branchesTitle.
  ///
  /// In en, this message translates to:
  /// **'Branches'**
  String get branchesTitle;

  /// No description provided for @newBranch.
  ///
  /// In en, this message translates to:
  /// **'New branch'**
  String get newBranch;

  /// No description provided for @editBranch.
  ///
  /// In en, this message translates to:
  /// **'Edit branch'**
  String get editBranch;

  /// No description provided for @returnsTitle.
  ///
  /// In en, this message translates to:
  /// **'Product returns'**
  String get returnsTitle;

  /// No description provided for @newReturn.
  ///
  /// In en, this message translates to:
  /// **'New return'**
  String get newReturn;

  /// No description provided for @returnSaved.
  ///
  /// In en, this message translates to:
  /// **'Return submitted for approval'**
  String get returnSaved;

  /// No description provided for @selectInvoice.
  ///
  /// In en, this message translates to:
  /// **'Invoice'**
  String get selectInvoice;

  /// No description provided for @invoicePickerLabel.
  ///
  /// In en, this message translates to:
  /// **'{id} Â· {customer} Â· {total}'**
  String invoicePickerLabel(Object id, Object customer, Object total);

  /// No description provided for @returnReason.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get returnReason;

  /// No description provided for @rejectReason.
  ///
  /// In en, this message translates to:
  /// **'Rejection reason'**
  String get rejectReason;

  /// No description provided for @returnTypeCustomer.
  ///
  /// In en, this message translates to:
  /// **'Customer return'**
  String get returnTypeCustomer;

  /// No description provided for @returnTypeSupplier.
  ///
  /// In en, this message translates to:
  /// **'Supplier return'**
  String get returnTypeSupplier;

  /// No description provided for @returnCondition.
  ///
  /// In en, this message translates to:
  /// **'Item condition'**
  String get returnCondition;

  /// No description provided for @conditionSellable.
  ///
  /// In en, this message translates to:
  /// **'Sellable'**
  String get conditionSellable;

  /// No description provided for @conditionDefective.
  ///
  /// In en, this message translates to:
  /// **'Defective'**
  String get conditionDefective;

  /// No description provided for @returnQty.
  ///
  /// In en, this message translates to:
  /// **'Return qty'**
  String get returnQty;

  /// No description provided for @noInvoiceLines.
  ///
  /// In en, this message translates to:
  /// **'This invoice has no line items'**
  String get noInvoiceLines;

  /// No description provided for @selectReturnLines.
  ///
  /// In en, this message translates to:
  /// **'Enter return quantity for at least one item'**
  String get selectReturnLines;

  /// No description provided for @approve.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get approve;

  /// No description provided for @reject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get reject;

  /// No description provided for @returnRowTitle.
  ///
  /// In en, this message translates to:
  /// **'{type} â€” {status}'**
  String returnRowTitle(Object type, Object status);

  /// No description provided for @reason.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get reason;

  /// No description provided for @installmentsTitle.
  ///
  /// In en, this message translates to:
  /// **'Installments'**
  String get installmentsTitle;

  /// No description provided for @overdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get overdue;

  /// No description provided for @pay.
  ///
  /// In en, this message translates to:
  /// **'Pay'**
  String get pay;

  /// No description provided for @dueDate.
  ///
  /// In en, this message translates to:
  /// **'Due {date}'**
  String dueDate(Object date);

  /// No description provided for @amountLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount: {amount}'**
  String amountLabel(Object amount);

  /// No description provided for @settlementsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settlements'**
  String get settlementsTitle;

  /// No description provided for @settlementsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Collect credit customer balances — daily or weekly (Saturday) cycles'**
  String get settlementsSubtitle;

  /// No description provided for @settlementsDueTab.
  ///
  /// In en, this message translates to:
  /// **'Due now'**
  String get settlementsDueTab;

  /// No description provided for @settlementsHistoryTab.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get settlementsHistoryTab;

  /// No description provided for @settlementsUpcomingEmpty.
  ///
  /// In en, this message translates to:
  /// **'No customers due for collection'**
  String get settlementsUpcomingEmpty;

  /// No description provided for @settlementsFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All due'**
  String get settlementsFilterAll;

  /// No description provided for @settlementsFilterDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get settlementsFilterDaily;

  /// No description provided for @settlementsFilterWeekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get settlementsFilterWeekly;

  /// No description provided for @settlementCycleLabel.
  ///
  /// In en, this message translates to:
  /// **'Settlement cycle'**
  String get settlementCycleLabel;

  /// No description provided for @settlementCycleWeekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly (Saturday)'**
  String get settlementCycleWeekly;

  /// No description provided for @settlementCycleDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get settlementCycleDaily;

  /// No description provided for @lastSettledAt.
  ///
  /// In en, this message translates to:
  /// **'Last collected'**
  String get lastSettledAt;

  /// No description provided for @amountDue.
  ///
  /// In en, this message translates to:
  /// **'Amount due'**
  String get amountDue;

  /// No description provided for @settleAll.
  ///
  /// In en, this message translates to:
  /// **'Settle all'**
  String get settleAll;

  /// No description provided for @partialPay.
  ///
  /// In en, this message translates to:
  /// **'Partial pay'**
  String get partialPay;

  /// No description provided for @recordSettlement.
  ///
  /// In en, this message translates to:
  /// **'Record settlement'**
  String get recordSettlement;

  /// No description provided for @selectCustomer.
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get selectCustomer;

  /// No description provided for @settlementCreditHint.
  ///
  /// In en, this message translates to:
  /// **'Only credit customers are listed. Saving settles all unpaid credit invoices for that customer.'**
  String get settlementCreditHint;

  /// No description provided for @noCreditCustomers.
  ///
  /// In en, this message translates to:
  /// **'No credit customers. Add a customer with type Credit on the Customers screen.'**
  String get noCreditCustomers;

  /// No description provided for @settlementSaved.
  ///
  /// In en, this message translates to:
  /// **'Settlement recorded'**
  String get settlementSaved;

  /// No description provided for @settlementCreditOnly.
  ///
  /// In en, this message translates to:
  /// **'Settlements apply to credit customers only'**
  String get settlementCreditOnly;

  /// No description provided for @settlementNoUnpaidInvoices.
  ///
  /// In en, this message translates to:
  /// **'No unpaid credit invoices for this customer'**
  String get settlementNoUnpaidInvoices;

  /// No description provided for @paymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Payment method'**
  String get paymentMethod;

  /// No description provided for @bankTransfer.
  ///
  /// In en, this message translates to:
  /// **'Bank transfer'**
  String get bankTransfer;

  /// No description provided for @paymentCheck.
  ///
  /// In en, this message translates to:
  /// **'Check'**
  String get paymentCheck;

  /// No description provided for @notesOptional.
  ///
  /// In en, this message translates to:
  /// **'Notes (optional)'**
  String get notesOptional;

  /// No description provided for @customerId.
  ///
  /// In en, this message translates to:
  /// **'Customer ID'**
  String get customerId;

  /// No description provided for @settlementRowSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{date} Â· {amount}'**
  String settlementRowSubtitle(Object date, Object amount);

  /// No description provided for @transfersTitle.
  ///
  /// In en, this message translates to:
  /// **'Stock transfers'**
  String get transfersTitle;

  /// No description provided for @newTransfer.
  ///
  /// In en, this message translates to:
  /// **'New transfer'**
  String get newTransfer;

  /// No description provided for @fromBranchId.
  ///
  /// In en, this message translates to:
  /// **'From branch ID'**
  String get fromBranchId;

  /// No description provided for @toBranchId.
  ///
  /// In en, this message translates to:
  /// **'To branch ID'**
  String get toBranchId;

  /// No description provided for @fromBranch.
  ///
  /// In en, this message translates to:
  /// **'From branch'**
  String get fromBranch;

  /// No description provided for @toBranch.
  ///
  /// In en, this message translates to:
  /// **'To branch'**
  String get toBranch;

  /// No description provided for @transferBranches.
  ///
  /// In en, this message translates to:
  /// **'{from} â†’ {to}'**
  String transferBranches(Object from, Object to);

  /// No description provided for @selectBranch.
  ///
  /// In en, this message translates to:
  /// **'Select a branch'**
  String get selectBranch;

  /// No description provided for @failedLoadBranches.
  ///
  /// In en, this message translates to:
  /// **'Could not load branches'**
  String get failedLoadBranches;

  /// No description provided for @selectPart.
  ///
  /// In en, this message translates to:
  /// **'Part / item'**
  String get selectPart;

  /// No description provided for @failedLoadParts.
  ///
  /// In en, this message translates to:
  /// **'Could not load parts'**
  String get failedLoadParts;

  /// No description provided for @noPartsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No parts available at this branch'**
  String get noPartsAvailable;

  /// No description provided for @transferSaved.
  ///
  /// In en, this message translates to:
  /// **'Transfer created'**
  String get transferSaved;

  /// No description provided for @maxQtyAvailable.
  ///
  /// In en, this message translates to:
  /// **'Maximum available: {qty}'**
  String maxQtyAvailable(Object qty);

  /// No description provided for @branchesMustDiffer.
  ///
  /// In en, this message translates to:
  /// **'Choose two different branches'**
  String get branchesMustDiffer;

  /// No description provided for @partId.
  ///
  /// In en, this message translates to:
  /// **'Part ID'**
  String get partId;

  /// No description provided for @transferRowTitle.
  ///
  /// In en, this message translates to:
  /// **'Transfer {id}'**
  String transferRowTitle(Object id);

  /// No description provided for @quantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get quantity;

  /// No description provided for @completeTransfer.
  ///
  /// In en, this message translates to:
  /// **'Complete transfer'**
  String get completeTransfer;

  /// No description provided for @cancelTransfer.
  ///
  /// In en, this message translates to:
  /// **'Cancel transfer'**
  String get cancelTransfer;

  /// No description provided for @pendingSyncTitle.
  ///
  /// In en, this message translates to:
  /// **'Pending sync'**
  String get pendingSyncTitle;

  /// No description provided for @syncing.
  ///
  /// In en, this message translates to:
  /// **'Syncingâ€¦'**
  String get syncing;

  /// No description provided for @syncNow.
  ///
  /// In en, this message translates to:
  /// **'Sync now'**
  String get syncNow;

  /// No description provided for @noPendingInvoices.
  ///
  /// In en, this message translates to:
  /// **'No pending invoices'**
  String get noPendingInvoices;

  /// No description provided for @pendingRowSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{status} Â· {total} Â· {date}'**
  String pendingRowSubtitle(Object status, Object total, Object date);

  /// No description provided for @salesReportTitle.
  ///
  /// In en, this message translates to:
  /// **'Sales report'**
  String get salesReportTitle;

  /// No description provided for @inventoryReportTitle.
  ///
  /// In en, this message translates to:
  /// **'Inventory valuation'**
  String get inventoryReportTitle;

  /// No description provided for @customersReportTitle.
  ///
  /// In en, this message translates to:
  /// **'Customer balances'**
  String get customersReportTitle;

  /// No description provided for @suppliersReportTitle.
  ///
  /// In en, this message translates to:
  /// **'Supplier debt'**
  String get suppliersReportTitle;

  /// No description provided for @returnsReportTitle.
  ///
  /// In en, this message translates to:
  /// **'Returns summary'**
  String get returnsReportTitle;

  /// No description provided for @reportsHubTitle.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get reportsHubTitle;

  /// No description provided for @reportsHubSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a report to understand sales, stock, debts, and returns'**
  String get reportsHubSubtitle;

  /// No description provided for @backToReports.
  ///
  /// In en, this message translates to:
  /// **'All reports'**
  String get backToReports;

  /// No description provided for @runReport.
  ///
  /// In en, this message translates to:
  /// **'Run report'**
  String get runReport;

  /// No description provided for @reportTapRun.
  ///
  /// In en, this message translates to:
  /// **'Set the date range (if shown), then tap Run report'**
  String get reportTapRun;

  /// No description provided for @reportDateRange.
  ///
  /// In en, this message translates to:
  /// **'{from} to {to}'**
  String reportDateRange(Object from, Object to);

  /// No description provided for @reportRowCount.
  ///
  /// In en, this message translates to:
  /// **'{count} rows'**
  String reportRowCount(Object count);

  /// No description provided for @reportDescSales.
  ///
  /// In en, this message translates to:
  /// **'All sales invoices in the selected period â€” number, customer, payment type, and total.'**
  String get reportDescSales;

  /// No description provided for @reportDescInventory.
  ///
  /// In en, this message translates to:
  /// **'Current stock value: quantity Ã— cost and Ã— sell price per part.'**
  String get reportDescInventory;

  /// No description provided for @reportDescCustomers.
  ///
  /// In en, this message translates to:
  /// **'Who owes you? Customer credit balances and oldest unpaid invoice date.'**
  String get reportDescCustomers;

  /// No description provided for @reportDescSuppliers.
  ///
  /// In en, this message translates to:
  /// **'What you owe suppliers? Total debt per supplier.'**
  String get reportDescSuppliers;

  /// No description provided for @reportDescReturns.
  ///
  /// In en, this message translates to:
  /// **'Returns in the period: count, value, and reasons.'**
  String get reportDescReturns;

  /// No description provided for @reportInvoiceCount.
  ///
  /// In en, this message translates to:
  /// **'Invoice count'**
  String get reportInvoiceCount;

  /// No description provided for @reportTotalSales.
  ///
  /// In en, this message translates to:
  /// **'Total sales'**
  String get reportTotalSales;

  /// No description provided for @reportReturnsCount.
  ///
  /// In en, this message translates to:
  /// **'Return count'**
  String get reportReturnsCount;

  /// No description provided for @reportReturnsValue.
  ///
  /// In en, this message translates to:
  /// **'Return value'**
  String get reportReturnsValue;

  /// No description provided for @reportByReason.
  ///
  /// In en, this message translates to:
  /// **'By reason'**
  String get reportByReason;

  /// No description provided for @reportReasonCount.
  ///
  /// In en, this message translates to:
  /// **'{count} times'**
  String reportReasonCount(Object count);

  /// No description provided for @colInvoiceNumber.
  ///
  /// In en, this message translates to:
  /// **'Invoice #'**
  String get colInvoiceNumber;

  /// No description provided for @colCustomerName.
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get colCustomerName;

  /// No description provided for @colBranchName.
  ///
  /// In en, this message translates to:
  /// **'Branch'**
  String get colBranchName;

  /// No description provided for @colPaymentType.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get colPaymentType;

  /// No description provided for @colTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get colTotal;

  /// No description provided for @colSubtotal.
  ///
  /// In en, this message translates to:
  /// **'Subtotal'**
  String get colSubtotal;

  /// No description provided for @colDiscount.
  ///
  /// In en, this message translates to:
  /// **'Discount'**
  String get colDiscount;

  /// No description provided for @colDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get colDate;

  /// No description provided for @colValueCost.
  ///
  /// In en, this message translates to:
  /// **'Value (cost)'**
  String get colValueCost;

  /// No description provided for @colValueSell.
  ///
  /// In en, this message translates to:
  /// **'Value (sell)'**
  String get colValueSell;

  /// No description provided for @colOutstanding.
  ///
  /// In en, this message translates to:
  /// **'Outstanding'**
  String get colOutstanding;

  /// No description provided for @colOldestInvoice.
  ///
  /// In en, this message translates to:
  /// **'Oldest invoice'**
  String get colOldestInvoice;

  /// No description provided for @colTotalDebt.
  ///
  /// In en, this message translates to:
  /// **'Total debt'**
  String get colTotalDebt;

  /// No description provided for @colUpdatedAt.
  ///
  /// In en, this message translates to:
  /// **'Updated'**
  String get colUpdatedAt;

  /// No description provided for @colCount.
  ///
  /// In en, this message translates to:
  /// **'Count'**
  String get colCount;

  /// No description provided for @editPart.
  ///
  /// In en, this message translates to:
  /// **'Edit part'**
  String get editPart;

  /// No description provided for @newPart.
  ///
  /// In en, this message translates to:
  /// **'New part'**
  String get newPart;

  /// No description provided for @code.
  ///
  /// In en, this message translates to:
  /// **'Code'**
  String get code;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @unit.
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get unit;

  /// No description provided for @selectCategory.
  ///
  /// In en, this message translates to:
  /// **'Select category'**
  String get selectCategory;

  /// No description provided for @selectUnit.
  ///
  /// In en, this message translates to:
  /// **'Select unit'**
  String get selectUnit;

  /// No description provided for @categoryOtherHint.
  ///
  /// In en, this message translates to:
  /// **'Category name (if not in list)'**
  String get categoryOtherHint;

  /// No description provided for @unitOtherHint.
  ///
  /// In en, this message translates to:
  /// **'Unit name (if not in list)'**
  String get unitOtherHint;

  /// No description provided for @fieldRequired.
  ///
  /// In en, this message translates to:
  /// **'This field is required'**
  String get fieldRequired;

  /// No description provided for @partSaved.
  ///
  /// In en, this message translates to:
  /// **'Part saved'**
  String get partSaved;

  /// No description provided for @partDeleted.
  ///
  /// In en, this message translates to:
  /// **'Part deleted'**
  String get partDeleted;

  /// No description provided for @confirmDeletePart.
  ///
  /// In en, this message translates to:
  /// **'Delete {name}? This cannot be undone if the part has no sales history.'**
  String confirmDeletePart(Object name);

  /// No description provided for @partCreateNotAllowed.
  ///
  /// In en, this message translates to:
  /// **'Only admins and managers can add parts'**
  String get partCreateNotAllowed;

  /// No description provided for @partAddOffline.
  ///
  /// In en, this message translates to:
  /// **'Connect to the internet to add products.'**
  String get partAddOffline;

  /// No description provided for @partBranchRequired.
  ///
  /// In en, this message translates to:
  /// **'Select a branch before adding a part'**
  String get partBranchRequired;

  /// No description provided for @openingQuantity.
  ///
  /// In en, this message translates to:
  /// **'Opening qty'**
  String get openingQuantity;

  /// No description provided for @partCodeDuplicate.
  ///
  /// In en, this message translates to:
  /// **'Part code already exists â€” use another code'**
  String get partCodeDuplicate;

  /// No description provided for @partFillCategoryUnit.
  ///
  /// In en, this message translates to:
  /// **'Select category and unit from the list'**
  String get partFillCategoryUnit;

  /// No description provided for @partInvalidUnit.
  ///
  /// In en, this message translates to:
  /// **'Invalid unit â€” pick from the list'**
  String get partInvalidUnit;

  /// No description provided for @failedLoadPartMeta.
  ///
  /// In en, this message translates to:
  /// **'Could not load categories or units â€” check connection'**
  String get failedLoadPartMeta;

  /// No description provided for @partCategoriesTitle.
  ///
  /// In en, this message translates to:
  /// **'Part categories'**
  String get partCategoriesTitle;

  /// No description provided for @partCategoriesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create and manage spare-part categories'**
  String get partCategoriesSubtitle;

  /// No description provided for @addCategory.
  ///
  /// In en, this message translates to:
  /// **'Add category'**
  String get addCategory;

  /// No description provided for @editCategory.
  ///
  /// In en, this message translates to:
  /// **'Edit category'**
  String get editCategory;

  /// No description provided for @categoryKey.
  ///
  /// In en, this message translates to:
  /// **'Key'**
  String get categoryKey;

  /// No description provided for @categoryKeyHint.
  ///
  /// In en, this message translates to:
  /// **'Lowercase letters, digits, and underscores only'**
  String get categoryKeyHint;

  /// No description provided for @categoryKeyInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid key â€” use a-z, 0-9, and _'**
  String get categoryKeyInvalid;

  /// No description provided for @categoryName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get categoryName;

  /// No description provided for @categoryActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get categoryActive;

  /// No description provided for @sortOrder.
  ///
  /// In en, this message translates to:
  /// **'Sort order'**
  String get sortOrder;

  /// No description provided for @deactivateCategoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Deactivate category'**
  String get deactivateCategoryTitle;

  /// No description provided for @deactivateCategoryConfirm.
  ///
  /// In en, this message translates to:
  /// **'This hides the category from new parts. Continue?'**
  String get deactivateCategoryConfirm;

  /// No description provided for @deactivate.
  ///
  /// In en, this message translates to:
  /// **'Deactivate'**
  String get deactivate;

  /// No description provided for @internetRequired.
  ///
  /// In en, this message translates to:
  /// **'Internet connection required'**
  String get internetRequired;

  /// No description provided for @partImage.
  ///
  /// In en, this message translates to:
  /// **'Part image'**
  String get partImage;

  /// No description provided for @choosePartImage.
  ///
  /// In en, this message translates to:
  /// **'Choose image'**
  String get choosePartImage;

  /// No description provided for @removePartImage.
  ///
  /// In en, this message translates to:
  /// **'Remove image'**
  String get removePartImage;

  /// No description provided for @partImageTooLarge.
  ///
  /// In en, this message translates to:
  /// **'Image exceeds 2 MB limit'**
  String get partImageTooLarge;

  /// No description provided for @partImageInvalidType.
  ///
  /// In en, this message translates to:
  /// **'Unsupported file type â€” use JPG, PNG, or WebP only'**
  String get partImageInvalidType;

  /// No description provided for @unitPc.
  ///
  /// In en, this message translates to:
  /// **'Piece'**
  String get unitPc;

  /// No description provided for @unitBox.
  ///
  /// In en, this message translates to:
  /// **'Box'**
  String get unitBox;

  /// No description provided for @unitSet.
  ///
  /// In en, this message translates to:
  /// **'Set'**
  String get unitSet;

  /// No description provided for @unitKg.
  ///
  /// In en, this message translates to:
  /// **'Kilogram'**
  String get unitKg;

  /// No description provided for @unitM.
  ///
  /// In en, this message translates to:
  /// **'Meter'**
  String get unitM;

  /// No description provided for @unitL.
  ///
  /// In en, this message translates to:
  /// **'Liter'**
  String get unitL;

  /// No description provided for @unitRoll.
  ///
  /// In en, this message translates to:
  /// **'Roll'**
  String get unitRoll;

  /// No description provided for @unitPack.
  ///
  /// In en, this message translates to:
  /// **'Pack'**
  String get unitPack;

  /// No description provided for @sellPrice.
  ///
  /// In en, this message translates to:
  /// **'Sell price'**
  String get sellPrice;

  /// No description provided for @costPrice.
  ///
  /// In en, this message translates to:
  /// **'Cost price'**
  String get costPrice;

  /// No description provided for @minStock.
  ///
  /// In en, this message translates to:
  /// **'Min stock'**
  String get minStock;

  /// No description provided for @partRowSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{category} · sell {sell} · cost {cost} · min {min}'**
  String partRowSubtitle(Object category, Object sell, Object cost, Object min);

  /// No description provided for @adjustStock.
  ///
  /// In en, this message translates to:
  /// **'Adjust stock'**
  String get adjustStock;

  /// No description provided for @stockAdjusted.
  ///
  /// In en, this message translates to:
  /// **'Stock updated'**
  String get stockAdjusted;

  /// No description provided for @branchId.
  ///
  /// In en, this message translates to:
  /// **'Branch ID'**
  String get branchId;

  /// No description provided for @quantityDelta.
  ///
  /// In en, this message translates to:
  /// **'Quantity delta'**
  String get quantityDelta;

  /// No description provided for @physicalCount.
  ///
  /// In en, this message translates to:
  /// **'Physical count'**
  String get physicalCount;

  /// No description provided for @branchRowLabel.
  ///
  /// In en, this message translates to:
  /// **'Branch: {name}'**
  String branchRowLabel(Object name);

  /// No description provided for @qtyRowLabel.
  ///
  /// In en, this message translates to:
  /// **'Qty: {qty}'**
  String qtyRowLabel(Object qty);

  /// No description provided for @serverTab.
  ///
  /// In en, this message translates to:
  /// **'Server'**
  String get serverTab;

  /// No description provided for @localPendingTab.
  ///
  /// In en, this message translates to:
  /// **'Local pending'**
  String get localPendingTab;

  /// No description provided for @invoiceDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Invoice {id}'**
  String invoiceDetailTitle(Object id);

  /// No description provided for @paymentValue.
  ///
  /// In en, this message translates to:
  /// **'Payment: {type}'**
  String paymentValue(Object type);

  /// No description provided for @totalValue.
  ///
  /// In en, this message translates to:
  /// **'Total: {amount}'**
  String totalValue(Object amount);

  /// No description provided for @quantityTimes.
  ///
  /// In en, this message translates to:
  /// **'Ã—{qty}'**
  String quantityTimes(Object qty);

  /// No description provided for @invoiceRowSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{payment} Â· {date}'**
  String invoiceRowSubtitle(Object payment, Object date);

  /// No description provided for @statusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get statusPending;

  /// No description provided for @statusPaid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get statusPaid;

  /// No description provided for @statusApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get statusApproved;

  /// No description provided for @statusRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get statusRejected;

  /// No description provided for @statusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get statusCompleted;

  /// No description provided for @statusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get statusCancelled;

  /// No description provided for @noStockForPart.
  ///
  /// In en, this message translates to:
  /// **'No stock for {code}'**
  String noStockForPart(Object code);

  /// No description provided for @insufficientStockFor.
  ///
  /// In en, this message translates to:
  /// **'Insufficient stock for {code}'**
  String insufficientStockFor(Object code);

  /// No description provided for @insufficientStock.
  ///
  /// In en, this message translates to:
  /// **'Insufficient stock'**
  String get insufficientStock;

  /// No description provided for @selectCustomerAndItems.
  ///
  /// In en, this message translates to:
  /// **'Select a customer and add items'**
  String get selectCustomerAndItems;

  /// No description provided for @creditSalesBlockedOffline.
  ///
  /// In en, this message translates to:
  /// **'Credit sales are not allowed while offline'**
  String get creditSalesBlockedOffline;

  /// No description provided for @creditSalesUnavailableOffline.
  ///
  /// In en, this message translates to:
  /// **'Credit sales may be unavailable offline'**
  String get creditSalesUnavailableOffline;

  /// No description provided for @productAnalysisTitle.
  ///
  /// In en, this message translates to:
  /// **'Product analysis'**
  String get productAnalysisTitle;

  /// No description provided for @productAnalysisSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sales and stock per part'**
  String get productAnalysisSubtitle;

  /// No description provided for @unitsSold.
  ///
  /// In en, this message translates to:
  /// **'Units sold'**
  String get unitsSold;

  /// No description provided for @revenue.
  ///
  /// In en, this message translates to:
  /// **'Revenue'**
  String get revenue;

  /// No description provided for @stockLevel.
  ///
  /// In en, this message translates to:
  /// **'Stock'**
  String get stockLevel;

  /// No description provided for @noProductData.
  ///
  /// In en, this message translates to:
  /// **'No product sales data yet'**
  String get noProductData;

  /// No description provided for @viewAllProducts.
  ///
  /// In en, this message translates to:
  /// **'View all parts'**
  String get viewAllProducts;

  /// No description provided for @partAnalysisTitle.
  ///
  /// In en, this message translates to:
  /// **'Part analysis'**
  String get partAnalysisTitle;

  /// No description provided for @partAnalysisSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Stock, sales, purchases, returns, and movements'**
  String get partAnalysisSubtitle;

  /// No description provided for @partAnalysisOnlineOnly.
  ///
  /// In en, this message translates to:
  /// **'Part analysis requires an internet connection'**
  String get partAnalysisOnlineOnly;

  /// No description provided for @salesPeriodTitle.
  ///
  /// In en, this message translates to:
  /// **'Sales (period)'**
  String get salesPeriodTitle;

  /// No description provided for @grossProfit.
  ///
  /// In en, this message translates to:
  /// **'Gross profit'**
  String get grossProfit;

  /// No description provided for @grossMargin.
  ///
  /// In en, this message translates to:
  /// **'Gross margin'**
  String get grossMargin;

  /// No description provided for @estimatedCogs.
  ///
  /// In en, this message translates to:
  /// **'Est. COGS'**
  String get estimatedCogs;

  /// No description provided for @valueAtCost.
  ///
  /// In en, this message translates to:
  /// **'Stock value (cost)'**
  String get valueAtCost;

  /// No description provided for @valueAtSell.
  ///
  /// In en, this message translates to:
  /// **'Stock value (sell)'**
  String get valueAtSell;

  /// No description provided for @marginPerUnit.
  ///
  /// In en, this message translates to:
  /// **'Margin per unit'**
  String get marginPerUnit;

  /// No description provided for @lowStockLabel.
  ///
  /// In en, this message translates to:
  /// **'Below min?'**
  String get lowStockLabel;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @salesByMonth.
  ///
  /// In en, this message translates to:
  /// **'Sales by month'**
  String get salesByMonth;

  /// No description provided for @stockByBranch.
  ///
  /// In en, this message translates to:
  /// **'Stock by branch'**
  String get stockByBranch;

  /// No description provided for @purchasesAndReturns.
  ///
  /// In en, this message translates to:
  /// **'Purchases & returns'**
  String get purchasesAndReturns;

  /// No description provided for @unitsPurchased.
  ///
  /// In en, this message translates to:
  /// **'Units purchased'**
  String get unitsPurchased;

  /// No description provided for @purchaseCost.
  ///
  /// In en, this message translates to:
  /// **'Purchase cost'**
  String get purchaseCost;

  /// No description provided for @purchaseOrderCount.
  ///
  /// In en, this message translates to:
  /// **'Purchase orders'**
  String get purchaseOrderCount;

  /// No description provided for @unitsReturned.
  ///
  /// In en, this message translates to:
  /// **'Units returned'**
  String get unitsReturned;

  /// No description provided for @returnsValue.
  ///
  /// In en, this message translates to:
  /// **'Returns value'**
  String get returnsValue;

  /// No description provided for @movementsByType.
  ///
  /// In en, this message translates to:
  /// **'Movements summary'**
  String get movementsByType;

  /// No description provided for @movementType.
  ///
  /// In en, this message translates to:
  /// **'Movement type'**
  String get movementType;

  /// No description provided for @recentMovements.
  ///
  /// In en, this message translates to:
  /// **'Recent movements'**
  String get recentMovements;

  /// No description provided for @createdBy.
  ///
  /// In en, this message translates to:
  /// **'Created by'**
  String get createdBy;

  /// No description provided for @allBranches.
  ///
  /// In en, this message translates to:
  /// **'All branches'**
  String get allBranches;

  /// No description provided for @movementPurchaseIn.
  ///
  /// In en, this message translates to:
  /// **'Purchase in'**
  String get movementPurchaseIn;

  /// No description provided for @movementSaleOut.
  ///
  /// In en, this message translates to:
  /// **'Sale out'**
  String get movementSaleOut;

  /// No description provided for @movementTransferIn.
  ///
  /// In en, this message translates to:
  /// **'Transfer in'**
  String get movementTransferIn;

  /// No description provided for @movementTransferOut.
  ///
  /// In en, this message translates to:
  /// **'Transfer out'**
  String get movementTransferOut;

  /// No description provided for @movementReturnIn.
  ///
  /// In en, this message translates to:
  /// **'Return in'**
  String get movementReturnIn;

  /// No description provided for @movementReturnOut.
  ///
  /// In en, this message translates to:
  /// **'Return out'**
  String get movementReturnOut;

  /// No description provided for @movementAdjustment.
  ///
  /// In en, this message translates to:
  /// **'Adjustment'**
  String get movementAdjustment;

  /// No description provided for @branchFinanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Branch finance'**
  String get branchFinanceTitle;

  /// No description provided for @branchFinanceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Inter-branch charges and payments from transfers'**
  String get branchFinanceSubtitle;

  /// No description provided for @branchBalancesTab.
  ///
  /// In en, this message translates to:
  /// **'Balances'**
  String get branchBalancesTab;

  /// No description provided for @branchLedgerTab.
  ///
  /// In en, this message translates to:
  /// **'Ledger'**
  String get branchLedgerTab;

  /// No description provided for @recordBranchCharge.
  ///
  /// In en, this message translates to:
  /// **'Record charge'**
  String get recordBranchCharge;

  /// No description provided for @recordBranchPayment.
  ///
  /// In en, this message translates to:
  /// **'Record payment'**
  String get recordBranchPayment;

  /// No description provided for @branchChargeSaved.
  ///
  /// In en, this message translates to:
  /// **'Charge recorded'**
  String get branchChargeSaved;

  /// No description provided for @branchPaymentSaved.
  ///
  /// In en, this message translates to:
  /// **'Payment recorded'**
  String get branchPaymentSaved;

  /// No description provided for @branchEntrySettled.
  ///
  /// In en, this message translates to:
  /// **'Entry settled'**
  String get branchEntrySettled;

  /// No description provided for @creditorBranch.
  ///
  /// In en, this message translates to:
  /// **'Creditor branch (owed to)'**
  String get creditorBranch;

  /// No description provided for @debtorBranch.
  ///
  /// In en, this message translates to:
  /// **'Debtor branch (owes)'**
  String get debtorBranch;

  /// No description provided for @balanceOwed.
  ///
  /// In en, this message translates to:
  /// **'Balance owed'**
  String get balanceOwed;

  /// No description provided for @totalCharges.
  ///
  /// In en, this message translates to:
  /// **'Total charges'**
  String get totalCharges;

  /// No description provided for @totalPayments.
  ///
  /// In en, this message translates to:
  /// **'Total payments'**
  String get totalPayments;

  /// No description provided for @openChargesCount.
  ///
  /// In en, this message translates to:
  /// **'Open charges'**
  String get openChargesCount;

  /// No description provided for @branchBalanceRow.
  ///
  /// In en, this message translates to:
  /// **'{debtor} owes {creditor}'**
  String branchBalanceRow(Object debtor, Object creditor);

  /// No description provided for @branchLedgerRow.
  ///
  /// In en, this message translates to:
  /// **'{debtor} â†’ {creditor} Â· {amount}'**
  String branchLedgerRow(Object debtor, Object creditor, Object amount);

  /// No description provided for @entryTypeCharge.
  ///
  /// In en, this message translates to:
  /// **'Charge'**
  String get entryTypeCharge;

  /// No description provided for @entryTypePayment.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get entryTypePayment;

  /// No description provided for @statusOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get statusOpen;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @markSettled.
  ///
  /// In en, this message translates to:
  /// **'Mark settled'**
  String get markSettled;

  /// No description provided for @editBranchFinanceEntry.
  ///
  /// In en, this message translates to:
  /// **'Edit entry'**
  String get editBranchFinanceEntry;

  /// No description provided for @voidBranchFinanceEntry.
  ///
  /// In en, this message translates to:
  /// **'Void entry'**
  String get voidBranchFinanceEntry;

  /// No description provided for @voidBranchFinanceEntryTitle.
  ///
  /// In en, this message translates to:
  /// **'Void this entry?'**
  String get voidBranchFinanceEntryTitle;

  /// No description provided for @voidBranchFinanceEntryHint.
  ///
  /// In en, this message translates to:
  /// **'The balance between branches will be updated. Transfer-linked charges must be reversed via the transfer screen.'**
  String get voidBranchFinanceEntryHint;

  /// No description provided for @branchFinanceEntryUpdated.
  ///
  /// In en, this message translates to:
  /// **'Entry updated'**
  String get branchFinanceEntryUpdated;

  /// No description provided for @branchFinanceEntryVoided.
  ///
  /// In en, this message translates to:
  /// **'Entry voided'**
  String get branchFinanceEntryVoided;

  /// No description provided for @entryVoided.
  ///
  /// In en, this message translates to:
  /// **'Voided'**
  String get entryVoided;

  /// No description provided for @needTwoBranches.
  ///
  /// In en, this message translates to:
  /// **'At least two branches are required'**
  String get needTwoBranches;

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// No description provided for @completeTransferHint.
  ///
  /// In en, this message translates to:
  /// **'Completing moves stock from source to destination. You can record an inter-branch charge.'**
  String get completeTransferHint;

  /// No description provided for @transferValuation.
  ///
  /// In en, this message translates to:
  /// **'Charge valuation'**
  String get transferValuation;

  /// No description provided for @valuationCost.
  ///
  /// In en, this message translates to:
  /// **'Cost price'**
  String get valuationCost;

  /// No description provided for @valuationSell.
  ///
  /// In en, this message translates to:
  /// **'Sell price'**
  String get valuationSell;

  /// No description provided for @recordInterBranchCharge.
  ///
  /// In en, this message translates to:
  /// **'Record inter-branch charge'**
  String get recordInterBranchCharge;

  /// No description provided for @recordBranchChargeHint.
  ///
  /// In en, this message translates to:
  /// **'Creates a ledger entry: receiving branch owes sending branch for stock value'**
  String get recordBranchChargeHint;

  /// No description provided for @transferCompleted.
  ///
  /// In en, this message translates to:
  /// **'Transfer completed'**
  String get transferCompleted;

  /// No description provided for @transferCompletedWithCharge.
  ///
  /// In en, this message translates to:
  /// **'Transfer completed; inter-branch charge recorded'**
  String get transferCompletedWithCharge;

  /// No description provided for @editTransfer.
  ///
  /// In en, this message translates to:
  /// **'Edit transfer'**
  String get editTransfer;

  /// No description provided for @transferEditPendingOnly.
  ///
  /// In en, this message translates to:
  /// **'Only pending transfers can be edited.'**
  String get transferEditPendingOnly;

  /// No description provided for @transferUpdated.
  ///
  /// In en, this message translates to:
  /// **'Transfer updated'**
  String get transferUpdated;

  /// No description provided for @reverseTransfer.
  ///
  /// In en, this message translates to:
  /// **'Reverse transfer'**
  String get reverseTransfer;

  /// No description provided for @reverseTransferTitle.
  ///
  /// In en, this message translates to:
  /// **'Reverse completed transfer?'**
  String get reverseTransferTitle;

  /// No description provided for @reverseTransferHint.
  ///
  /// In en, this message translates to:
  /// **'Stock returns to the source branch and the inter-branch charge is voided. Dashboard realized cash is not affected.'**
  String get reverseTransferHint;

  /// No description provided for @transferReversed.
  ///
  /// In en, this message translates to:
  /// **'Transfer reversed'**
  String get transferReversed;

  /// No description provided for @editPayment.
  ///
  /// In en, this message translates to:
  /// **'Edit payment'**
  String get editPayment;

  /// No description provided for @editPaymentHint.
  ///
  /// In en, this message translates to:
  /// **'Only the most recent payment can be corrected.'**
  String get editPaymentHint;

  /// No description provided for @paymentUpdated.
  ///
  /// In en, this message translates to:
  /// **'Payment updated'**
  String get paymentUpdated;

  /// No description provided for @partsSalesChartTitle.
  ///
  /// In en, this message translates to:
  /// **'Parts sales chart'**
  String get partsSalesChartTitle;

  /// No description provided for @partsSalesChartSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Top-selling parts by month for the year'**
  String get partsSalesChartSubtitle;

  /// No description provided for @dashboardPartsChartSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Top 5 parts by month during {year}'**
  String dashboardPartsChartSubtitle(Object year);

  /// No description provided for @viewFullChart.
  ///
  /// In en, this message translates to:
  /// **'Full report'**
  String get viewFullChart;

  /// No description provided for @reportDescPartsSalesChart.
  ///
  /// In en, this message translates to:
  /// **'Monthly trend for top parts â€” by units or revenue.'**
  String get reportDescPartsSalesChart;

  /// No description provided for @year.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get year;

  /// No description provided for @rankBy.
  ///
  /// In en, this message translates to:
  /// **'Rank by'**
  String get rankBy;

  /// No description provided for @rankByUnits.
  ///
  /// In en, this message translates to:
  /// **'Units'**
  String get rankByUnits;

  /// No description provided for @rankByRevenue.
  ///
  /// In en, this message translates to:
  /// **'Revenue'**
  String get rankByRevenue;

  /// No description provided for @limit.
  ///
  /// In en, this message translates to:
  /// **'Limit'**
  String get limit;

  /// No description provided for @topPartsYear.
  ///
  /// In en, this message translates to:
  /// **'Top parts â€” {year}'**
  String topPartsYear(Object year);

  /// No description provided for @financialReportTitle.
  ///
  /// In en, this message translates to:
  /// **'Financial report (P&L)'**
  String get financialReportTitle;

  /// No description provided for @reportDescFinancial.
  ///
  /// In en, this message translates to:
  /// **'Revenue, discounts, refunds, gross profit, and net profit by period. Returns use approval date.'**
  String get reportDescFinancial;

  /// No description provided for @colRevenue.
  ///
  /// In en, this message translates to:
  /// **'Revenue'**
  String get colRevenue;

  /// No description provided for @colGrossProfit.
  ///
  /// In en, this message translates to:
  /// **'Gross profit'**
  String get colGrossProfit;

  /// No description provided for @financialReturnsSection.
  ///
  /// In en, this message translates to:
  /// **'Returns in period'**
  String get financialReturnsSection;

  /// No description provided for @financialCustomerReturns.
  ///
  /// In en, this message translates to:
  /// **'Customer returns'**
  String get financialCustomerReturns;

  /// No description provided for @financialSupplierReturns.
  ///
  /// In en, this message translates to:
  /// **'Supplier returns'**
  String get financialSupplierReturns;

  /// No description provided for @financialByBranch.
  ///
  /// In en, this message translates to:
  /// **'By branch'**
  String get financialByBranch;

  /// No description provided for @financialReturnsApprovalNote.
  ///
  /// In en, this message translates to:
  /// **'Returns are counted by approval date (completed_at), not create date.'**
  String get financialReturnsApprovalNote;

  /// No description provided for @usersTitle.
  ///
  /// In en, this message translates to:
  /// **'Users'**
  String get usersTitle;

  /// No description provided for @usersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage staff accounts, roles, and branch assignment (admin only).'**
  String get usersSubtitle;

  /// No description provided for @newUser.
  ///
  /// In en, this message translates to:
  /// **'New user'**
  String get newUser;

  /// No description provided for @editUser.
  ///
  /// In en, this message translates to:
  /// **'Edit user'**
  String get editUser;

  /// No description provided for @userSaved.
  ///
  /// In en, this message translates to:
  /// **'User saved'**
  String get userSaved;

  /// No description provided for @userDeactivated.
  ///
  /// In en, this message translates to:
  /// **'User deactivated'**
  String get userDeactivated;

  /// No description provided for @deactivateUser.
  ///
  /// In en, this message translates to:
  /// **'Deactivate user'**
  String get deactivateUser;

  /// No description provided for @deactivateUserConfirm.
  ///
  /// In en, this message translates to:
  /// **'Deactivate {name}? They will no longer be able to sign in.'**
  String deactivateUserConfirm(Object name);

  /// No description provided for @role.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get role;

  /// No description provided for @posSelectBranch.
  ///
  /// In en, this message translates to:
  /// **'Select branch for this sale'**
  String get posSelectBranch;

  /// No description provided for @posBranchRequiredHint.
  ///
  /// In en, this message translates to:
  /// **'Choose a branch before adding items or completing a sale.'**
  String get posBranchRequiredHint;

  /// No description provided for @businessCapitalTitle.
  ///
  /// In en, this message translates to:
  /// **'Business capital'**
  String get businessCapitalTitle;

  /// No description provided for @businessCapitalSubtitleAdmin.
  ///
  /// In en, this message translates to:
  /// **'Adjust opening cash when the drawer count differs from the system. Total capital = inventory + realized cash.'**
  String get businessCapitalSubtitleAdmin;

  /// No description provided for @businessCapitalSubtitleView.
  ///
  /// In en, this message translates to:
  /// **'Computed from inventory at cost plus cash on hand (read-only).'**
  String get businessCapitalSubtitleView;

  /// No description provided for @businessCapitalAmount.
  ///
  /// In en, this message translates to:
  /// **'Business capital'**
  String get businessCapitalAmount;

  /// No description provided for @businessCapitalFormulaHint.
  ///
  /// In en, this message translates to:
  /// **'Inventory at cost + cash on hand'**
  String get businessCapitalFormulaHint;

  /// No description provided for @openingCashBalance.
  ///
  /// In en, this message translates to:
  /// **'Opening cash balance'**
  String get openingCashBalance;

  /// No description provided for @openingCashSet.
  ///
  /// In en, this message translates to:
  /// **'Set opening cash'**
  String get openingCashSet;

  /// No description provided for @openingCashUpdateTitle.
  ///
  /// In en, this message translates to:
  /// **'Update opening cash balance'**
  String get openingCashUpdateTitle;

  /// No description provided for @openingCashUpdateHint.
  ///
  /// In en, this message translates to:
  /// **'Sets the opening cash in the drawer, not total business capital. Inventory is added automatically.'**
  String get openingCashUpdateHint;

  /// No description provided for @openingCashSaved.
  ///
  /// In en, this message translates to:
  /// **'Opening cash balance saved'**
  String get openingCashSaved;

  /// No description provided for @openingCashDefaultReason.
  ///
  /// In en, this message translates to:
  /// **'Opening drawer count'**
  String get openingCashDefaultReason;

  /// No description provided for @businessCapitalSet.
  ///
  /// In en, this message translates to:
  /// **'Update capital'**
  String get businessCapitalSet;

  /// No description provided for @businessCapitalUpdateTitle.
  ///
  /// In en, this message translates to:
  /// **'Update business capital'**
  String get businessCapitalUpdateTitle;

  /// No description provided for @businessCapitalSaved.
  ///
  /// In en, this message translates to:
  /// **'Business capital saved'**
  String get businessCapitalSaved;

  /// No description provided for @businessCapitalDefaultReason.
  ///
  /// In en, this message translates to:
  /// **'Capital adjustment'**
  String get businessCapitalDefaultReason;

  /// No description provided for @businessCapitalNotSet.
  ///
  /// In en, this message translates to:
  /// **'Capital not configured yet. An admin can set it below.'**
  String get businessCapitalNotSet;

  /// No description provided for @businessCapitalHistory.
  ///
  /// In en, this message translates to:
  /// **'Capital history'**
  String get businessCapitalHistory;

  /// No description provided for @branchFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All branches'**
  String get branchFilterAll;

  /// No description provided for @branchFilterLabel.
  ///
  /// In en, this message translates to:
  /// **'Branch'**
  String get branchFilterLabel;

  /// No description provided for @branchFilterClear.
  ///
  /// In en, this message translates to:
  /// **'Clear branch filter'**
  String get branchFilterClear;

  /// No description provided for @withdrawFromProfit.
  ///
  /// In en, this message translates to:
  /// **'Withdraw from profit'**
  String get withdrawFromProfit;

  /// No description provided for @withdrawableProfit.
  ///
  /// In en, this message translates to:
  /// **'Withdrawable profit'**
  String get withdrawableProfit;

  /// No description provided for @realizedProfit.
  ///
  /// In en, this message translates to:
  /// **'Realized profit'**
  String get realizedProfit;

  /// No description provided for @totalProfitWithdrawn.
  ///
  /// In en, this message translates to:
  /// **'Total withdrawn'**
  String get totalProfitWithdrawn;

  /// No description provided for @profitWithdrawnSuccess.
  ///
  /// In en, this message translates to:
  /// **'Profit withdrawn'**
  String get profitWithdrawnSuccess;

  /// No description provided for @noWithdrawableProfit.
  ///
  /// In en, this message translates to:
  /// **'No withdrawable profit available'**
  String get noWithdrawableProfit;

  /// No description provided for @ownerCashOutTitle.
  ///
  /// In en, this message translates to:
  /// **'Owner cash out'**
  String get ownerCashOutTitle;

  /// No description provided for @ownerCashOutSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Deducted from profit margin, not opening cash. Cash on hand and business capital decrease when money leaves the drawer.'**
  String get ownerCashOutSubtitle;

  /// No description provided for @ownerCashOutDialogHint.
  ///
  /// In en, this message translates to:
  /// **'Opening cash balance is not changed. Only realized profit limits this withdrawal.'**
  String get ownerCashOutDialogHint;

  /// No description provided for @ownerCashOutRecord.
  ///
  /// In en, this message translates to:
  /// **'Cash out'**
  String get ownerCashOutRecord;

  /// No description provided for @ownerCashOutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get ownerCashOutConfirm;

  /// No description provided for @ownerCashOutAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get ownerCashOutAmount;

  /// No description provided for @ownerCashOutReason.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get ownerCashOutReason;

  /// No description provided for @ownerCashOutSuccess.
  ///
  /// In en, this message translates to:
  /// **'Cash out recorded'**
  String get ownerCashOutSuccess;

  /// No description provided for @ownerCashOutHistory.
  ///
  /// In en, this message translates to:
  /// **'Cash out history'**
  String get ownerCashOutHistory;

  /// No description provided for @ownerCashOutAmountInvalid.
  ///
  /// In en, this message translates to:
  /// **'Amount must be between 0.01 and {max}'**
  String ownerCashOutAmountInvalid(Object max);

  /// No description provided for @capitalInventoryAtCost.
  ///
  /// In en, this message translates to:
  /// **'Inventory (at cost)'**
  String get capitalInventoryAtCost;

  /// No description provided for @capitalCustomerReceivables.
  ///
  /// In en, this message translates to:
  /// **'Customer receivables'**
  String get capitalCustomerReceivables;

  /// No description provided for @capitalSupplierDebt.
  ///
  /// In en, this message translates to:
  /// **'Supplier debt'**
  String get capitalSupplierDebt;

  /// No description provided for @capitalDeployed.
  ///
  /// In en, this message translates to:
  /// **'Deployed capital'**
  String get capitalDeployed;

  /// No description provided for @capitalEstimatedAvailable.
  ///
  /// In en, this message translates to:
  /// **'Est. available cash'**
  String get capitalEstimatedAvailable;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @invalidAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid amount'**
  String get invalidAmount;

  /// No description provided for @weeklyDiscount.
  ///
  /// In en, this message translates to:
  /// **'Weekly discounts'**
  String get weeklyDiscount;

  /// No description provided for @weeklyGrossProfit.
  ///
  /// In en, this message translates to:
  /// **'Weekly gross profit'**
  String get weeklyGrossProfit;

  /// No description provided for @dashboardPurchasesTitle.
  ///
  /// In en, this message translates to:
  /// **'Purchases & supplier debt'**
  String get dashboardPurchasesTitle;

  /// No description provided for @dashboardPurchasesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'POs, installments, and payments this week'**
  String get dashboardPurchasesSubtitle;

  /// No description provided for @costOfGoods.
  ///
  /// In en, this message translates to:
  /// **'Cost of goods'**
  String get costOfGoods;

  /// No description provided for @dashboardSnapshotTitle.
  ///
  /// In en, this message translates to:
  /// **'Current position'**
  String get dashboardSnapshotTitle;

  /// No description provided for @dashboardSnapshotSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Snapshot — does not change with the period tab'**
  String get dashboardSnapshotSubtitle;

  /// No description provided for @periodNetCashFlowDay.
  ///
  /// In en, this message translates to:
  /// **'Net cash flow — today'**
  String get periodNetCashFlowDay;

  /// No description provided for @periodNetCashFlowWeek.
  ///
  /// In en, this message translates to:
  /// **'Net cash flow — this week'**
  String get periodNetCashFlowWeek;

  /// No description provided for @periodNetCashFlowMonth.
  ///
  /// In en, this message translates to:
  /// **'Net cash flow — this month'**
  String get periodNetCashFlowMonth;

  /// No description provided for @dashboardFinanceOverview.
  ///
  /// In en, this message translates to:
  /// **'Financial overview'**
  String get dashboardFinanceOverview;

  /// No description provided for @dashboardFinanceOverviewSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Capital, cash, and obligations in one place'**
  String get dashboardFinanceOverviewSubtitle;

  /// No description provided for @dashboardPeriodActivity.
  ///
  /// In en, this message translates to:
  /// **'Period activity'**
  String get dashboardPeriodActivity;

  /// No description provided for @cashOnHandRealized.
  ///
  /// In en, this message translates to:
  /// **'Cash on hand'**
  String get cashOnHandRealized;

  /// No description provided for @mustCollectCustomers.
  ///
  /// In en, this message translates to:
  /// **'Must collect from customers'**
  String get mustCollectCustomers;

  /// No description provided for @mustPaySuppliers.
  ///
  /// In en, this message translates to:
  /// **'Must pay suppliers'**
  String get mustPaySuppliers;

  /// No description provided for @weeklyNetCashFlowRealized.
  ///
  /// In en, this message translates to:
  /// **'Weekly net cash flow'**
  String get weeklyNetCashFlowRealized;

  /// No description provided for @weeklyCashInRealized.
  ///
  /// In en, this message translates to:
  /// **'Weekly cash in'**
  String get weeklyCashInRealized;

  /// No description provided for @weeklyCashOutRealized.
  ///
  /// In en, this message translates to:
  /// **'Weekly cash out'**
  String get weeklyCashOutRealized;

  /// No description provided for @legacyEstimatedAvailable.
  ///
  /// In en, this message translates to:
  /// **'Legacy estimate'**
  String get legacyEstimatedAvailable;

  /// No description provided for @totalSupplierDebt.
  ///
  /// In en, this message translates to:
  /// **'Total supplier debt'**
  String get totalSupplierDebt;

  /// No description provided for @unpaidInstallmentsTotal.
  ///
  /// In en, this message translates to:
  /// **'Unpaid installments'**
  String get unpaidInstallmentsTotal;

  /// No description provided for @unpaidInstallmentsCount.
  ///
  /// In en, this message translates to:
  /// **'Unpaid installments'**
  String get unpaidInstallmentsCount;

  /// No description provided for @overdueInstallmentsTotal.
  ///
  /// In en, this message translates to:
  /// **'Overdue installments'**
  String get overdueInstallmentsTotal;

  /// No description provided for @weeklySupplierPayments.
  ///
  /// In en, this message translates to:
  /// **'Supplier payments (week)'**
  String get weeklySupplierPayments;

  /// No description provided for @weeklyPurchasesOrdered.
  ///
  /// In en, this message translates to:
  /// **'Purchases ordered (week)'**
  String get weeklyPurchasesOrdered;

  /// No description provided for @weeklyPurchasesReceived.
  ///
  /// In en, this message translates to:
  /// **'Purchases received (week)'**
  String get weeklyPurchasesReceived;

  /// No description provided for @periodRevenue.
  ///
  /// In en, this message translates to:
  /// **'Revenue'**
  String get periodRevenue;

  /// No description provided for @periodNetSales.
  ///
  /// In en, this message translates to:
  /// **'Net sales'**
  String get periodNetSales;

  /// No description provided for @periodDiscount.
  ///
  /// In en, this message translates to:
  /// **'Discounts'**
  String get periodDiscount;

  /// No description provided for @periodGrossProfit.
  ///
  /// In en, this message translates to:
  /// **'Gross profit'**
  String get periodGrossProfit;

  /// No description provided for @periodCustomerRefunds.
  ///
  /// In en, this message translates to:
  /// **'Customer refunds'**
  String get periodCustomerRefunds;

  /// No description provided for @periodNetCashFlowRealized.
  ///
  /// In en, this message translates to:
  /// **'Net cash flow'**
  String get periodNetCashFlowRealized;

  /// No description provided for @periodCashInRealized.
  ///
  /// In en, this message translates to:
  /// **'Cash in'**
  String get periodCashInRealized;

  /// No description provided for @periodCashOutRealized.
  ///
  /// In en, this message translates to:
  /// **'Cash out'**
  String get periodCashOutRealized;

  /// No description provided for @periodCashInDay.
  ///
  /// In en, this message translates to:
  /// **'Cash in — today'**
  String get periodCashInDay;

  /// No description provided for @periodCashInWeek.
  ///
  /// In en, this message translates to:
  /// **'Cash in — this week'**
  String get periodCashInWeek;

  /// No description provided for @periodCashInMonth.
  ///
  /// In en, this message translates to:
  /// **'Cash in — this month'**
  String get periodCashInMonth;

  /// No description provided for @periodCashOutDay.
  ///
  /// In en, this message translates to:
  /// **'Cash out — today'**
  String get periodCashOutDay;

  /// No description provided for @periodCashOutWeek.
  ///
  /// In en, this message translates to:
  /// **'Cash out — this week'**
  String get periodCashOutWeek;

  /// No description provided for @periodCashOutMonth.
  ///
  /// In en, this message translates to:
  /// **'Cash out — this month'**
  String get periodCashOutMonth;

  /// No description provided for @periodSupplierPayments.
  ///
  /// In en, this message translates to:
  /// **'Supplier payments'**
  String get periodSupplierPayments;

  /// No description provided for @periodPurchasesOrdered.
  ///
  /// In en, this message translates to:
  /// **'Purchases ordered'**
  String get periodPurchasesOrdered;

  /// No description provided for @periodPurchasesReceived.
  ///
  /// In en, this message translates to:
  /// **'Purchases received'**
  String get periodPurchasesReceived;

  /// No description provided for @payablesOverdueInstallments.
  ///
  /// In en, this message translates to:
  /// **'Overdue installments'**
  String get payablesOverdueInstallments;

  /// No description provided for @payablesUpcomingInstallments.
  ///
  /// In en, this message translates to:
  /// **'Upcoming installments'**
  String get payablesUpcomingInstallments;

  /// No description provided for @viewInstallments.
  ///
  /// In en, this message translates to:
  /// **'View installments'**
  String get viewInstallments;

  /// No description provided for @averageCost.
  ///
  /// In en, this message translates to:
  /// **'Average cost'**
  String get averageCost;

  /// No description provided for @catalogCostRollup.
  ///
  /// In en, this message translates to:
  /// **'Weighted average cost'**
  String get catalogCostRollup;

  /// No description provided for @costFromPurchasesHint.
  ///
  /// In en, this message translates to:
  /// **'Leave blank to use the current branch average.'**
  String get costFromPurchasesHint;

  /// No description provided for @catalogCostRollupHint.
  ///
  /// In en, this message translates to:
  /// **'Catalog rollup — branch costs update from purchases and stock receipts.'**
  String get catalogCostRollupHint;

  /// No description provided for @adjustUnitCostOptional.
  ///
  /// In en, this message translates to:
  /// **'Unit cost (optional)'**
  String get adjustUnitCostOptional;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
