// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'نور الإسلام';

  @override
  String get appSubtitle => 'نظام إدارة ERB-Frezzer';

  @override
  String get appTagline =>
      'المخزون والمبيعات وعمليات الفروع\nفي مساحة عمل واحدة.';

  @override
  String get welcomeBack => 'مرحباً بعودتك';

  @override
  String get signInToContinue => 'سجّل الدخول للمتابعة';

  @override
  String get email => 'البريد الإلكتروني';

  @override
  String get password => 'كلمة المرور';

  @override
  String get signIn => 'تسجيل الدخول';

  @override
  String get online => 'متصل';

  @override
  String get offline => 'غير متصل';

  @override
  String get offlineBanner => 'غير متصل — يمكن حفظ المبيعات الجديدة محلياً فقط';

  @override
  String get dismiss => 'إغلاق';

  @override
  String get sync => 'مزامنة';

  @override
  String get logout => 'تسجيل الخروج';

  @override
  String get branch => 'الفرع';

  @override
  String get user => 'المستخدم';

  @override
  String get navDashboard => 'لوحة التحكم';

  @override
  String get navPos => 'نقطة البيع';

  @override
  String get navParts => 'القطع';

  @override
  String get navStock => 'المخزون';

  @override
  String get navCustomers => 'العملاء';

  @override
  String get navSales => 'المبيعات';

  @override
  String get navSettle => 'التسويات';

  @override
  String get navSupply => 'الموردون';

  @override
  String get navPurchases => 'المشتريات';

  @override
  String get navReturns => 'المرتجعات';

  @override
  String get navReports => 'التقارير';

  @override
  String get navBranches => 'الفروع';

  @override
  String get navTransfers => 'التحويلات';

  @override
  String get navBranchFinance => 'حسابات الفروع';

  @override
  String get navInstallments => 'الأقساط';

  @override
  String get navPending => 'قيد الانتظار';

  @override
  String get navLocalSales => 'مبيعات محلية';

  @override
  String get navSettings => 'الإعدادات';

  @override
  String get dashboardTitle => 'لوحة التحكم';

  @override
  String get dashboardSubtitle => 'نظرة سريعة على المبيعات والمخزون والأموال';

  @override
  String get dashboardNeedsAttention => 'يحتاج انتباهك';

  @override
  String get dashboardAllClear => 'كل شيء على ما يرام';

  @override
  String get activityLogTitle => 'سجل النشاط';

  @override
  String get activityLogSubtitle => 'آخر التغييرات في متجرك';

  @override
  String get activityInvoiceCreated => 'تم تسجيل بيع جديد';

  @override
  String get activityInvoiceUpdated => 'تم تحديث فاتورة بيع';

  @override
  String get activityInvoiceCancelled => 'تم إلغاء بيع';

  @override
  String get activityInventoryAdjusted => 'تم تعديل كمية المخزون';

  @override
  String get activityPurchaseCreated => 'تم إنشاء أمر شراء';

  @override
  String get activityPurchaseReceived => 'تم استلام مشتريات في المخزون';

  @override
  String get activityCustomerCreated => 'تم إضافة عميل جديد';

  @override
  String get activityCustomerUpdated => 'تم تحديث بيانات عميل';

  @override
  String get activitySettlementRecorded => 'تم تسجيل دفعة عميل';

  @override
  String get activityTransferCreated => 'تم إنشاء تحويل مخزون';

  @override
  String get activityTransferCompleted => 'تم إتمام تحويل مخزون';

  @override
  String get activityReturnApproved => 'تمت الموافقة على مرتجع';

  @override
  String get activityReturnRejected => 'تم رفض مرتجع';

  @override
  String get activityPartCreated => 'تمت إضافة قطعة للكتالوج';

  @override
  String get activityPartUpdated => 'تم تحديث بيانات قطعة';

  @override
  String get activitySupplierCreated => 'تم إضافة مورد جديد';

  @override
  String get activitySyncCompleted => 'اكتملت مزامنة البيانات';

  @override
  String activityGeneric(Object action, Object entity) {
    return '$action · $entity';
  }

  @override
  String get entityInvoice => 'المبيعات';

  @override
  String get entityStock => 'المخزون';

  @override
  String get entityCustomer => 'العملاء';

  @override
  String get entityPurchase => 'المشتريات';

  @override
  String get entitySupplier => 'الموردون';

  @override
  String get entityPart => 'القطع';

  @override
  String get entityTransfer => 'التحويلات';

  @override
  String get entityReturn => 'المرتجعات';

  @override
  String get entitySettlement => 'التسويات';

  @override
  String get entityBranch => 'الفروع';

  @override
  String get noDebtors => 'لا يوجد مدينون حالياً';

  @override
  String get noCreditors => 'لا يوجد دائنون حالياً';

  @override
  String get noStockAlerts => 'مستويات المخزون جيدة';

  @override
  String get openPos => 'فتح نقطة البيع';

  @override
  String get viewInventory => 'عرض المخزون';

  @override
  String get todaySales => 'مبيعات اليوم';

  @override
  String get todayProfit => 'ربح اليوم';

  @override
  String get weeklyProfit => 'ربح الأسبوع';

  @override
  String get weeklyRevenue => 'إيراد الأسبوع';

  @override
  String get weeklyCost => 'تكلفة الأسبوع';

  @override
  String get profitAmount => 'الربح';

  @override
  String get todayCost => 'تكلفة البضاعة (اليوم)';

  @override
  String get todayInvoices => 'فواتير اليوم';

  @override
  String get todayProfitEstimated => 'محسوب من مبيعات اليوم وتكلفة القطع';

  @override
  String profitMargin(Object percent) {
    return 'الهامش: $percent٪';
  }

  @override
  String get lowStock => 'مخزون منخفض';

  @override
  String get overdueInstallments => 'أقساط متأخرة';

  @override
  String get pendingCredit => 'ائتمان معلق';

  @override
  String get salesTrend => 'اتجاه المبيعات';

  @override
  String get recentActivity => 'النشاط الأخير';

  @override
  String get noRecentActivity => 'لا يوجد نشاط حديث';

  @override
  String get loadingDashboard => 'جاري تحميل لوحة التحكم…';

  @override
  String get posTitle => 'نقطة البيع — بيع جديد';

  @override
  String get posSubtitle => 'ابحث عن قطعة أو امسح الباركود لإضافتها للسلة';

  @override
  String get searchScanBarcode => 'بحث / مسح الباركود';

  @override
  String get searchPartToAdd => 'ابحث عن قطعة للإضافة';

  @override
  String get cart => 'السلة';

  @override
  String get customer => 'العميل';

  @override
  String get cash => 'نقدي';

  @override
  String get credit => 'آجل';

  @override
  String get discount => 'الخصم';

  @override
  String get cartEmpty => 'السلة فارغة';

  @override
  String get subtotal => 'المجموع الفرعي';

  @override
  String get total => 'الإجمالي';

  @override
  String get clear => 'مسح';

  @override
  String get completeSale => 'إتمام البيع';

  @override
  String get processing => 'جاري المعالجة…';

  @override
  String get invalidLinePrice => 'أدخل سعراً أكبر من صفر لكل بند في السلة';

  @override
  String get price => 'السعر';

  @override
  String get available => 'متوفر';

  @override
  String get settingsTitle => 'الإعدادات';

  @override
  String get settingsSubtitle => 'تفضيلات التطبيق والمزامنة';

  @override
  String get apiConnection => 'اتصال API';

  @override
  String get apiHostHint => 'المضيف فقط — يُضاف /api/v1 تلقائياً';

  @override
  String get apiBaseUrl => 'رابط API الأساسي';

  @override
  String get offlineCashOnly => 'نقدي فقط عند عدم الاتصال';

  @override
  String get offlineCashOnlyHint => 'منع الدفع الآجل عند عدم الاتصال';

  @override
  String get lastCatalogSync => 'آخر مزامنة للكتالوج';

  @override
  String get never => 'أبداً';

  @override
  String get saveSettings => 'حفظ الإعدادات';

  @override
  String get settingsSaved => 'تم حفظ الإعدادات';

  @override
  String get language => 'اللغة';

  @override
  String get languageArabic => 'العربية';

  @override
  String get languageEnglish => 'English';

  @override
  String get printerSettings => 'إعدادات الطابعة';

  @override
  String get openPrinterSettings => 'إعداد الطابعة';

  @override
  String get customersTitle => 'العملاء';

  @override
  String get search => 'بحث';

  @override
  String get newCustomer => 'عميل جديد';

  @override
  String get inventoryTitle => 'المخزون';

  @override
  String get lowStockFilter => 'مخزون منخفض';

  @override
  String get adjust => 'تعديل';

  @override
  String get receipt => 'إيصال';

  @override
  String get receiptPending => 'إيصال (بانتظار المزامنة)';

  @override
  String get newSale => 'بيع جديد';

  @override
  String get printReceipt => 'طباعة الإيصال';

  @override
  String get printing => 'جاري الطباعة…';

  @override
  String get printSuccess => 'تم إرسال الإيصال للطابعة';

  @override
  String printFailed(String error) {
    return 'فشلت الطباعة: $error';
  }

  @override
  String get somethingWentWrong => 'حدث خطأ';

  @override
  String get tryAgain => 'إعادة المحاولة';

  @override
  String get nothingHereYet => 'لا يوجد محتوى بعد';

  @override
  String get printerDiscovery => 'اكتشاف الطابعات';

  @override
  String get printerRefresh => 'تحديث القائمة';

  @override
  String get printerSelect => 'اختر الطابعة';

  @override
  String get printerConnect => 'اتصال';

  @override
  String get printerDisconnect => 'قطع الاتصال';

  @override
  String get printerConnected => 'متصل';

  @override
  String get printerDisconnected => 'غير متصل';

  @override
  String get printerNotConnected => 'الطابعة غير متصلة';

  @override
  String get paperWidth => 'عرض الورق';

  @override
  String get paperWidth58 => '58 مم';

  @override
  String get paperWidth80 => '80 مم';

  @override
  String get companyName => 'اسم الشركة';

  @override
  String get footerText => 'التذييل';

  @override
  String get phoneNumber => 'رقم الهاتف';

  @override
  String get printTestPage => 'طباعة صفحة اختبار';

  @override
  String get savePrinterSettings => 'حفظ إعدادات الطابعة';

  @override
  String get printerSettingsSaved => 'تم حفظ إعدادات الطابعة';

  @override
  String get noPrintersFound => 'لم يتم العثور على طابعات';

  @override
  String get autoPrintOnSale => 'طباعة تلقائية بعد البيع';

  @override
  String get currencyEgp => 'جنيه';

  @override
  String get invoiceNumber => 'فاتورة #';

  @override
  String get date => 'التاريخ';

  @override
  String get items => 'الأصناف';

  @override
  String get payment => 'الدفع';

  @override
  String get partsTitle => 'القطع';

  @override
  String get invoicesTitle => 'المبيعات';

  @override
  String get localSalesTitle => 'مبيعات محلية';

  @override
  String get suppliersTitle => 'الموردون';

  @override
  String get newSupplier => 'مورد جديد';

  @override
  String get editSupplier => 'تعديل مورد';

  @override
  String get supplierName => 'الاسم';

  @override
  String get supplierAddress => 'العنوان';

  @override
  String get supplierEmail => 'البريد الإلكتروني';

  @override
  String get supplierDebt => 'الدين المستحق';

  @override
  String get save => 'حفظ';

  @override
  String get cancel => 'إلغاء';

  @override
  String get close => 'إغلاق';

  @override
  String get edit => 'تعديل';

  @override
  String get delete => 'حذف';

  @override
  String get nameRequired => 'الاسم مطلوب';

  @override
  String get supplierSaved => 'تم حفظ المورد';

  @override
  String get supplierDeleted => 'تم حذف المورد';

  @override
  String get contactPerson => 'جهة الاتصال';

  @override
  String get purchasesTitle => 'أوامر الشراء';

  @override
  String get newPurchase => 'أمر شراء جديد';

  @override
  String get purchaseOrder => 'أمر';

  @override
  String get purchaseSaved => 'تم إنشاء أمر الشراء';

  @override
  String get supplier => 'المورد';

  @override
  String get description => 'الوصف';

  @override
  String get paymentImmediate => 'فوري';

  @override
  String get paymentInstallments => 'أقساط';

  @override
  String get installmentCount => 'عدد الأقساط';

  @override
  String get installmentStartDate => 'تاريخ أول قسط';

  @override
  String get lineItems => 'البنود';

  @override
  String get part => 'القطعة';

  @override
  String get qty => 'الكمية';

  @override
  String get unitCost => 'تكلفة الوحدة';

  @override
  String get addLine => 'إضافة بند';

  @override
  String get receive => 'استلام';

  @override
  String get noSuppliersHint => 'أنشئ مورداً أولاً';

  @override
  String get branchRequired => 'يجب ربط المستخدم بفرع';

  @override
  String get addAtLeastOneLine => 'أضف بنداً واحداً على الأقل';

  @override
  String get receivablesTitle => 'المدينون (عملاء)';

  @override
  String get payablesTitle => 'الدائنون (موردون)';

  @override
  String get inventoryAlertsTitle => 'تنبيهات المخزون';

  @override
  String get totalReceivable => 'إجمالي المستحق';

  @override
  String get totalPayable => 'إجمالي المطلوب';

  @override
  String get topDebtors => 'أعلى المدينين';

  @override
  String get topCreditors => 'أعلى الدائنين';

  @override
  String get configurePrinterFirst => 'اضبط الطابعة من الإعدادات أولاً';

  @override
  String get name => 'الاسم';

  @override
  String get active => 'نشط';

  @override
  String get inactive => 'غير نشط';

  @override
  String get create => 'إنشاء';

  @override
  String get newAction => 'جديد';

  @override
  String get noData => 'لا توجد بيانات';

  @override
  String get balance => 'الرصيد';

  @override
  String balanceValue(Object amount) {
    return 'الرصيد: $amount';
  }

  @override
  String get editCustomer => 'تعديل عميل';

  @override
  String get customerType => 'نوع العميل';

  @override
  String get creditLimit => 'حد الائتمان';

  @override
  String customerRowSubtitle(Object type, Object balance) {
    return '$type · $balance';
  }

  @override
  String get customerSaved => 'تم حفظ العميل';

  @override
  String get branchesTitle => 'الفروع';

  @override
  String get newBranch => 'فرع جديد';

  @override
  String get editBranch => 'تعديل فرع';

  @override
  String get returnsTitle => 'مرتجعات المنتجات';

  @override
  String get newReturn => 'مرتجع جديد';

  @override
  String get returnSaved => 'تم إرسال المرتجع للموافقة';

  @override
  String get selectInvoice => 'الفاتورة';

  @override
  String invoicePickerLabel(Object id, Object customer, Object total) {
    return '$id · $customer · $total';
  }

  @override
  String get returnReason => 'السبب';

  @override
  String get rejectReason => 'سبب الرفض';

  @override
  String get returnTypeCustomer => 'مرتجع عميل';

  @override
  String get returnTypeSupplier => 'مرتجع مورد';

  @override
  String get returnCondition => 'حالة القطعة';

  @override
  String get conditionSellable => 'صالحة للبيع';

  @override
  String get conditionDefective => 'معيبة';

  @override
  String get returnQty => 'كمية المرتجع';

  @override
  String get noInvoiceLines => 'لا توجد بنود في هذه الفاتورة';

  @override
  String get selectReturnLines => 'أدخل كمية المرتجع لبند واحد على الأقل';

  @override
  String get approve => 'موافقة';

  @override
  String get reject => 'رفض';

  @override
  String returnRowTitle(Object type, Object status) {
    return '$type — $status';
  }

  @override
  String get reason => 'السبب';

  @override
  String get installmentsTitle => 'الأقساط';

  @override
  String get overdue => 'متأخر';

  @override
  String get pay => 'دفع';

  @override
  String dueDate(Object date) {
    return 'استحقاق $date';
  }

  @override
  String amountLabel(Object amount) {
    return 'المبلغ: $amount';
  }

  @override
  String get settlementsTitle => 'التسويات';

  @override
  String get settlementsSubtitle =>
      'تسوية حسابات العملاء الآجلة (السبت) — تسدد الفواتير غير المدفوعة تلقائياً';

  @override
  String get recordSettlement => 'تسجيل تسوية';

  @override
  String get selectCustomer => 'العميل';

  @override
  String get settlementCreditHint =>
      'يظهر العملاء الآجلون فقط. عند الحفظ تُسدَّد كل الفواتير الآجلة غير المدفوعة لهذا العميل.';

  @override
  String get noCreditCustomers =>
      'لا يوجد عملاء آجلون. أضف عميلاً من نوع «آجل» في شاشة العملاء.';

  @override
  String get settlementSaved => 'تم تسجيل التسوية';

  @override
  String get settlementCreditOnly => 'التسوية للعملاء الآجلين فقط';

  @override
  String get settlementNoUnpaidInvoices =>
      'لا توجد فواتير آجلة غير مدفوعة لهذا العميل';

  @override
  String get paymentMethod => 'طريقة الدفع';

  @override
  String get bankTransfer => 'تحويل بنكي';

  @override
  String get paymentCheck => 'شيك';

  @override
  String get notesOptional => 'ملاحظات (اختياري)';

  @override
  String get customerId => 'معرّف العميل';

  @override
  String settlementRowSubtitle(Object date, Object amount) {
    return '$date · $amount';
  }

  @override
  String get transfersTitle => 'تحويلات المخزون';

  @override
  String get newTransfer => 'تحويل جديد';

  @override
  String get fromBranchId => 'من فرع (معرّف)';

  @override
  String get toBranchId => 'إلى فرع (معرّف)';

  @override
  String get fromBranch => 'من فرع';

  @override
  String get toBranch => 'إلى فرع';

  @override
  String transferBranches(Object from, Object to) {
    return '$from ← $to';
  }

  @override
  String get selectBranch => 'اختر الفرع';

  @override
  String get failedLoadBranches => 'تعذر تحميل الفروع';

  @override
  String get selectPart => 'القطعة / الصنف';

  @override
  String get failedLoadParts => 'تعذر تحميل القطع';

  @override
  String get noPartsAvailable => 'لا توجد قطع متاحة في هذا الفرع';

  @override
  String get transferSaved => 'تم إنشاء التحويل';

  @override
  String maxQtyAvailable(Object qty) {
    return 'الحد الأقصى المتاح: $qty';
  }

  @override
  String get branchesMustDiffer => 'اختر فرعين مختلفين';

  @override
  String get partId => 'معرّف القطعة';

  @override
  String transferRowTitle(Object id) {
    return 'تحويل $id';
  }

  @override
  String get quantity => 'الكمية';

  @override
  String get completeTransfer => 'إتمام التحويل';

  @override
  String get cancelTransfer => 'إلغاء التحويل';

  @override
  String get pendingSyncTitle => 'مزامنة معلّقة';

  @override
  String get syncing => 'جاري المزامنة…';

  @override
  String get syncNow => 'مزامنة الآن';

  @override
  String get noPendingInvoices => 'لا توجد فواتير معلّقة';

  @override
  String pendingRowSubtitle(Object status, Object total, Object date) {
    return '$status · $total · $date';
  }

  @override
  String get salesReportTitle => 'تقرير المبيعات';

  @override
  String get inventoryReportTitle => 'تقييم المخزون';

  @override
  String get customersReportTitle => 'أرصدة العملاء';

  @override
  String get suppliersReportTitle => 'ديون الموردين';

  @override
  String get returnsReportTitle => 'ملخص المرتجعات';

  @override
  String get reportsHubTitle => 'التقارير';

  @override
  String get reportsHubSubtitle =>
      'اختر تقريراً لمعرفة المبيعات والمخزون والديون والمرتجعات';

  @override
  String get backToReports => 'كل التقارير';

  @override
  String get runReport => 'عرض التقرير';

  @override
  String get reportTapRun => 'حدّد الفترة (إن وُجدت) ثم اضغط «عرض التقرير»';

  @override
  String reportDateRange(Object from, Object to) {
    return 'من $from إلى $to';
  }

  @override
  String reportRowCount(Object count) {
    return '$count سجل';
  }

  @override
  String get reportDescSales =>
      'كل فواتير البيع في الفترة المحددة — رقم الفاتورة، العميل، طريقة الدفع، والإجمالي.';

  @override
  String get reportDescInventory =>
      'قيمة المخزون الحالي: الكمية × التكلفة و× سعر البيع لكل قطعة.';

  @override
  String get reportDescCustomers =>
      'من يدين لكم؟ أرصدة العملاء الآجلة وتاريخ أقدم فاتورة غير مسدّدة.';

  @override
  String get reportDescSuppliers =>
      'ماذا تدينون للموردين؟ إجمالي الديون لكل مورد.';

  @override
  String get reportDescReturns =>
      'ملخص المرتجعات في الفترة: العدد، القيمة، والأسباب.';

  @override
  String get reportInvoiceCount => 'عدد الفواتير';

  @override
  String get reportTotalSales => 'إجمالي المبيعات';

  @override
  String get reportReturnsCount => 'عدد المرتجعات';

  @override
  String get reportReturnsValue => 'قيمة المرتجعات';

  @override
  String get reportByReason => 'حسب السبب';

  @override
  String reportReasonCount(Object count) {
    return '$count مرة';
  }

  @override
  String get colInvoiceNumber => 'رقم الفاتورة';

  @override
  String get colCustomerName => 'العميل';

  @override
  String get colBranchName => 'الفرع';

  @override
  String get colPaymentType => 'طريقة الدفع';

  @override
  String get colTotal => 'الإجمالي';

  @override
  String get colSubtotal => 'المجموع الفرعي';

  @override
  String get colDiscount => 'الخصم';

  @override
  String get colDate => 'التاريخ';

  @override
  String get colValueCost => 'قيمة بالتكلفة';

  @override
  String get colValueSell => 'قيمة بالبيع';

  @override
  String get colOutstanding => 'الرصيد المستحق';

  @override
  String get colOldestInvoice => 'أقدم فاتورة';

  @override
  String get colTotalDebt => 'إجمالي الدين';

  @override
  String get colUpdatedAt => 'آخر تحديث';

  @override
  String get colCount => 'العدد';

  @override
  String get editPart => 'تعديل قطعة';

  @override
  String get newPart => 'قطعة جديدة';

  @override
  String get code => 'الكود';

  @override
  String get category => 'الفئة';

  @override
  String get unit => 'الوحدة';

  @override
  String get selectCategory => 'اختر الفئة';

  @override
  String get selectUnit => 'اختر الوحدة';

  @override
  String get categoryOtherHint => 'اسم الفئة (إن لم تكن في القائمة)';

  @override
  String get unitOtherHint => 'اسم الوحدة (إن لم تكن في القائمة)';

  @override
  String get fieldRequired => 'هذا الحقل مطلوب';

  @override
  String get partSaved => 'تم حفظ القطعة';

  @override
  String get partCreateNotAllowed => 'إضافة القطع متاحة للمدير فقط';

  @override
  String get partCodeDuplicate => 'كود القطعة مستخدم مسبقاً — غيّر الكود';

  @override
  String get partFillCategoryUnit => 'اختر الفئة والوحدة من القائمة';

  @override
  String get partInvalidUnit => 'وحدة غير صالحة — اختر من القائمة';

  @override
  String get failedLoadPartMeta =>
      'تعذر تحميل الفئات أو الوحدات — تحقق من الاتصال';

  @override
  String get partCategoriesTitle => 'فئات القطع';

  @override
  String get partCategoriesSubtitle => 'إنشاء وإدارة فئات قطع الغيار';

  @override
  String get addCategory => 'إضافة فئة';

  @override
  String get editCategory => 'تعديل الفئة';

  @override
  String get categoryKey => 'المفتاح';

  @override
  String get categoryKeyHint => 'أحرف إنجليزية صغيرة وأرقام و _ فقط';

  @override
  String get categoryKeyInvalid => 'مفتاح غير صالح — استخدم a-z و 0-9 و _';

  @override
  String get categoryName => 'الاسم';

  @override
  String get categoryActive => 'نشطة';

  @override
  String get sortOrder => 'ترتيب العرض';

  @override
  String get deactivateCategoryTitle => 'إلغاء تفعيل الفئة';

  @override
  String get deactivateCategoryConfirm =>
      'ستُخفى الفئة من قائمة الإضافة للقطع الجديدة. المتابعة؟';

  @override
  String get deactivate => 'إلغاء التفعيل';

  @override
  String get internetRequired => 'يتطلب اتصالاً بالإنترنت';

  @override
  String get partImage => 'صورة القطعة';

  @override
  String get choosePartImage => 'اختيار صورة';

  @override
  String get removePartImage => 'إزالة الصورة';

  @override
  String get partImageTooLarge => 'حجم الصورة يتجاوز 2 ميجابايت';

  @override
  String get partImageInvalidType =>
      'نوع ملف غير مدعوم — JPG أو PNG أو WebP فقط';

  @override
  String get unitPc => 'قطعة';

  @override
  String get unitBox => 'علبة';

  @override
  String get unitSet => 'مجموعة';

  @override
  String get unitKg => 'كيلوغرام';

  @override
  String get unitM => 'متر';

  @override
  String get unitL => 'لتر';

  @override
  String get unitRoll => 'رول';

  @override
  String get unitPack => 'حزمة';

  @override
  String get sellPrice => 'سعر البيع';

  @override
  String get costPrice => 'سعر التكلفة';

  @override
  String get minStock => 'الحد الأدنى';

  @override
  String partRowSubtitle(Object category, Object sell, Object min) {
    return '$category · بيع $sell · حد $min';
  }

  @override
  String get adjustStock => 'تعديل المخزون';

  @override
  String get stockAdjusted => 'تم تعديل المخزون';

  @override
  String get branchId => 'معرّف الفرع';

  @override
  String get quantityDelta => 'فرق الكمية';

  @override
  String get physicalCount => 'جرد فعلي';

  @override
  String branchRowLabel(Object name) {
    return 'الفرع: $name';
  }

  @override
  String qtyRowLabel(Object qty) {
    return 'الكمية: $qty';
  }

  @override
  String get serverTab => 'الخادم';

  @override
  String get localPendingTab => 'محلي معلّق';

  @override
  String invoiceDetailTitle(Object id) {
    return 'فاتورة $id';
  }

  @override
  String paymentValue(Object type) {
    return 'الدفع: $type';
  }

  @override
  String totalValue(Object amount) {
    return 'الإجمالي: $amount';
  }

  @override
  String quantityTimes(Object qty) {
    return '×$qty';
  }

  @override
  String invoiceRowSubtitle(Object payment, Object date) {
    return '$payment · $date';
  }

  @override
  String get statusPending => 'قيد الانتظار';

  @override
  String get statusPaid => 'مدفوع';

  @override
  String get statusApproved => 'موافق عليه';

  @override
  String get statusRejected => 'مرفوض';

  @override
  String get statusCompleted => 'مكتمل';

  @override
  String get statusCancelled => 'ملغى';

  @override
  String noStockForPart(Object code) {
    return 'لا مخزون للقطعة $code';
  }

  @override
  String insufficientStockFor(Object code) {
    return 'مخزون غير كافٍ للقطعة $code';
  }

  @override
  String get insufficientStock => 'مخزون غير كافٍ';

  @override
  String get selectCustomerAndItems => 'اختر عميلاً وأضف أصنافاً';

  @override
  String get creditSalesBlockedOffline => 'لا يُسمح بالبيع الآجل دون اتصال';

  @override
  String get creditSalesUnavailableOffline =>
      'قد لا يتوفر البيع الآجل دون اتصال';

  @override
  String get productAnalysisTitle => 'تحليل المنتجات';

  @override
  String get productAnalysisSubtitle => 'المبيعات والمخزون لكل قطعة';

  @override
  String get unitsSold => 'الوحدات المباعة';

  @override
  String get revenue => 'الإيراد';

  @override
  String get stockLevel => 'المخزون';

  @override
  String get noProductData => 'لا توجد بيانات مبيعات للمنتجات بعد';

  @override
  String get viewAllProducts => 'عرض كل القطع';

  @override
  String get partAnalysisTitle => 'تحليل القطعة';

  @override
  String get partAnalysisSubtitle =>
      'المخزون والمبيعات والمشتريات والمرتجعات وحركات المخزون';

  @override
  String get partAnalysisOnlineOnly => 'تحليل القطعة يتطلب اتصالاً بالإنترنت';

  @override
  String get salesPeriodTitle => 'المبيعات (الفترة)';

  @override
  String get grossProfit => 'إجمالي الربح';

  @override
  String get grossMargin => 'هامش الربح';

  @override
  String get estimatedCogs => 'تكلفة البضاعة (تقديري)';

  @override
  String get valueAtCost => 'قيمة المخزون (تكلفة)';

  @override
  String get valueAtSell => 'قيمة المخزون (بيع)';

  @override
  String get marginPerUnit => 'هامش الوحدة';

  @override
  String get lowStockLabel => 'أقل من الحد؟';

  @override
  String get yes => 'نعم';

  @override
  String get no => 'لا';

  @override
  String get salesByMonth => 'المبيعات شهرياً';

  @override
  String get stockByBranch => 'المخزون حسب الفرع';

  @override
  String get purchasesAndReturns => 'المشتريات والمرتجعات';

  @override
  String get unitsPurchased => 'وحدات مشتراة';

  @override
  String get purchaseCost => 'تكلفة الشراء';

  @override
  String get purchaseOrderCount => 'أوامر الشراء';

  @override
  String get unitsReturned => 'وحدات مرتجعة';

  @override
  String get returnsValue => 'قيمة المرتجعات';

  @override
  String get movementsByType => 'ملخص الحركات';

  @override
  String get movementType => 'نوع الحركة';

  @override
  String get recentMovements => 'آخر الحركات';

  @override
  String get createdBy => 'بواسطة';

  @override
  String get allBranches => 'كل الفروع';

  @override
  String get movementPurchaseIn => 'شراء (دخول)';

  @override
  String get movementSaleOut => 'بيع (خروج)';

  @override
  String get movementTransferIn => 'تحويل وارد';

  @override
  String get movementTransferOut => 'تحويل صادر';

  @override
  String get movementReturnIn => 'مرتجع (دخول)';

  @override
  String get movementReturnOut => 'مرتجع (خروج)';

  @override
  String get movementAdjustment => 'تسوية مخزون';

  @override
  String get branchFinanceTitle => 'حسابات الفروع';

  @override
  String get branchFinanceSubtitle => 'مستحقات التحويلات والمدفوعات بين الفروع';

  @override
  String get branchBalancesTab => 'الأرصدة';

  @override
  String get branchLedgerTab => 'السجل';

  @override
  String get recordBranchCharge => 'تسجيل مستحق';

  @override
  String get recordBranchPayment => 'تسجيل دفعة';

  @override
  String get branchChargeSaved => 'تم تسجيل المستحق';

  @override
  String get branchPaymentSaved => 'تم تسجيل الدفعة';

  @override
  String get branchEntrySettled => 'تم تسوية القيد';

  @override
  String get creditorBranch => 'الفرع الدائن (يستحق)';

  @override
  String get debtorBranch => 'الفرع المدين (يدين)';

  @override
  String get balanceOwed => 'المتبقي';

  @override
  String get totalCharges => 'إجمالي المستحقات';

  @override
  String get totalPayments => 'إجمالي المدفوعات';

  @override
  String get openChargesCount => 'مستحقات مفتوحة';

  @override
  String branchBalanceRow(Object debtor, Object creditor) {
    return '$debtor يدين لـ $creditor';
  }

  @override
  String branchLedgerRow(Object debtor, Object creditor, Object amount) {
    return '$debtor → $creditor · $amount';
  }

  @override
  String get entryTypeCharge => 'مستحق';

  @override
  String get entryTypePayment => 'دفعة';

  @override
  String get statusOpen => 'مفتوح';

  @override
  String get filterAll => 'الكل';

  @override
  String get markSettled => 'تسوية';

  @override
  String get needTwoBranches => 'يلزم فرعان على الأقل';

  @override
  String get amount => 'المبلغ';

  @override
  String get completeTransferHint =>
      'عند الإكمال يُخصم المخزون من الفرع المرسل ويُضاف للمستلم. يمكن تسجيل مستحق بين الفروع.';

  @override
  String get transferValuation => 'تقييم المستحق';

  @override
  String get valuationCost => 'سعر التكلفة';

  @override
  String get valuationSell => 'سعر البيع';

  @override
  String get recordInterBranchCharge => 'تسجيل مستحق بين الفروع';

  @override
  String get recordBranchChargeHint =>
      'يُنشئ قيداً مالياً: الفرع المستلم يدين للمرسل بقيمة البضاعة';

  @override
  String get transferCompleted => 'تم إكمال التحويل';

  @override
  String get transferCompletedWithCharge =>
      'تم إكمال التحويل وتسجيل المستحق بين الفروع';

  @override
  String get partsSalesChartTitle => 'مبيعات القطع (رسم بياني)';

  @override
  String get partsSalesChartSubtitle => 'أكثر القطع مبيعاً شهرياً خلال السنة';

  @override
  String dashboardPartsChartSubtitle(Object year) {
    return 'أفضل 5 قطع مبيعاً — شهراً بشهر خلال $year';
  }

  @override
  String get viewFullChart => 'التقرير الكامل';

  @override
  String get reportDescPartsSalesChart =>
      'خط زمني لأفضل القطع مبيعاً — حسب الوحدات أو الإيراد، شهراً بشهر.';

  @override
  String get year => 'السنة';

  @override
  String get rankBy => 'ترتيب حسب';

  @override
  String get rankByUnits => 'الوحدات';

  @override
  String get rankByRevenue => 'الإيراد';

  @override
  String get limit => 'العدد';

  @override
  String topPartsYear(Object year) {
    return 'أفضل القطع — $year';
  }
}
