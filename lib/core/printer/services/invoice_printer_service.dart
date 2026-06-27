import 'package:logging/logging.dart';

import '../../../data/models/invoice_model.dart';
import '../../../data/models/invoice_receipt_model.dart';
import '../models/customer_week_statement.dart';
import '../models/daily_sales_report.dart';
import '../models/printer_settings.dart';
import '../repository/printer_repository.dart';
import 'esc_pos_receipt_builder.dart';
import 'printer_service.dart';

class InvoicePrintData {
  const InvoicePrintData({
    required this.invoiceNumber,
    required this.invoiceDate,
    required this.items,
    required this.subtotal,
    required this.total,
    this.discount = 0,
    this.paymentMethod,
    this.customerName,
    this.branchName,
    this.amountPaid,
    this.changeDue,
  });

  final String invoiceNumber;
  final String invoiceDate;
  final List<InvoiceItemModel> items;
  final double subtotal;
  final double total;
  final double discount;
  final String? paymentMethod;
  final String? customerName;
  final String? branchName;
  final double? amountPaid;
  final double? changeDue;

  bool get isCash => (paymentMethod ?? '').toLowerCase() == 'cash';

  factory InvoicePrintData.fromModel(InvoiceModel model) {
    var subtotal = model.subtotal;
    if (subtotal <= 0 && model.items.isNotEmpty) {
      subtotal = model.items.fold(
        0.0,
        (sum, i) => sum + (i.lineTotal ?? (i.unitPrice ?? 0) * i.quantity),
      );
    }
    return InvoicePrintData(
      invoiceNumber: model.displayNumber,
      invoiceDate: model.createdAt ?? DateTime.now().toIso8601String().split('T').first,
      items: model.items,
      subtotal: subtotal,
      total: model.total,
      discount: model.discount,
      paymentMethod: model.paymentType,
      customerName: model.customerName,
      branchName: model.branchName,
      amountPaid: (model.paymentType.toLowerCase() == 'cash')
          ? model.amountPaid
          : null,
    );
  }

  InvoicePrintData copyWith({
    String? invoiceNumber,
    String? invoiceDate,
    List<InvoiceItemModel>? items,
    double? subtotal,
    double? total,
    double? discount,
    String? paymentMethod,
    String? customerName,
    String? branchName,
    double? amountPaid,
    double? changeDue,
  }) {
    return InvoicePrintData(
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      invoiceDate: invoiceDate ?? this.invoiceDate,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      total: total ?? this.total,
      discount: discount ?? this.discount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      customerName: customerName ?? this.customerName,
      branchName: branchName ?? this.branchName,
      amountPaid: amountPaid ?? this.amountPaid,
      changeDue: changeDue ?? this.changeDue,
    );
  }
}

class InvoicePrinterService {
  InvoicePrinterService(this._printerService, this._repository)
      : _builder = EscPosReceiptBuilder();

  final PrinterService _printerService;
  final PrinterRepository _repository;
  final EscPosReceiptBuilder _builder;
  final _log = Logger('InvoicePrinterService');

  PrinterSettings get settings => _repository.loadSettings();

  Future<void> printTestPage() async {
    final bytes = await _builder.buildTestPage(settings);
    await _printerService.printRaw(bytes);
  }

  Future<void> printInvoice(InvoicePrintData data) async {
    _log.info('Printing invoice ${data.invoiceNumber}');
    final bytes = await _builder.buildInvoice(
      settings: settings,
      invoiceNumber: data.invoiceNumber,
      invoiceDate: data.invoiceDate,
      items: data.items,
      subtotal: data.subtotal,
      total: data.total,
      discount: data.discount,
      paymentMethod: data.paymentMethod,
      customerName: data.customerName,
      branchName: data.branchName,
      amountPaid: data.amountPaid,
      changeDue: data.changeDue,
    );
    await _printerService.printRaw(bytes);
  }

  Future<void> printInvoiceModel(InvoiceModel model) =>
      printInvoice(InvoicePrintData.fromModel(model));

  /// One print job — each invoice is a separate cut on the roll.
  Future<void> printInvoicesBatch(List<InvoicePrintData> invoices) async {
    if (invoices.isEmpty) return;
    _log.info('Batch printing ${invoices.length} invoices');
    final bytes = <int>[];
    for (final data in invoices) {
      bytes.addAll(
        await _builder.buildInvoice(
          settings: settings,
          invoiceNumber: data.invoiceNumber,
          invoiceDate: data.invoiceDate,
          items: data.items,
          subtotal: data.subtotal,
          total: data.total,
          discount: data.discount,
          paymentMethod: data.paymentMethod,
          customerName: data.customerName,
          branchName: data.branchName,
          amountPaid: data.amountPaid,
          changeDue: data.changeDue,
        ),
      );
    }
    await _printerService.printRaw(bytes);
  }

  Future<void> printInvoiceModelsBatch(List<InvoiceModel> models) =>
      printInvoicesBatch(
        models.map(InvoicePrintData.fromModel).toList(),
      );

  Future<void> printReceiptStatement(InvoiceReceiptModel receipt) async {
    final num = receipt.invoice.invoiceNumber ?? 'receipt';
    _log.info('Printing receipt statement $num');
    final bytes = await _builder.buildInvoiceReceiptStatement(
      settings: settings,
      receipt: receipt,
    );
    await _printerService.printRaw(bytes);
  }

  Future<void> printDailySalesReport(
    DailySalesReport report, {
    bool compact = false,
  }) async {
    _log.info(
      'Printing daily sales report ${report.date} '
      '(${report.invoiceCount} invoices)',
    );
    final bytes = await _builder.buildDailySalesReport(
      settings: settings,
      report: report,
      compact: compact,
    );
    await _printerService.printRaw(bytes);
  }

  Future<void> printDailyDrawerReport(DailySalesReport report) async {
    _log.info('Printing daily drawer report ${report.date}');
    final bytes = await _builder.buildDailyDrawerReport(
      settings: settings,
      report: report,
    );
    await _printerService.printRaw(bytes);
  }

  Future<void> printCustomerWeeklyStatement(
    CustomerWeekStatement statement,
  ) async {
    _log.info('Printing weekly statement for ${statement.customerName}');
    final bytes = await _builder.buildCustomerWeeklyStatement(
      settings: settings,
      statement: statement,
    );
    await _printerService.printRaw(bytes);
  }
}
