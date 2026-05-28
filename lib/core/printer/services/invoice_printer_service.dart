import 'package:logging/logging.dart';

import '../../../data/models/invoice_model.dart';
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
  });

  final String invoiceNumber;
  final String invoiceDate;
  final List<InvoiceItemModel> items;
  final double subtotal;
  final double total;
  final double discount;
  final String? paymentMethod;
  final String? customerName;

  factory InvoicePrintData.fromModel(InvoiceModel model) {
    var subtotal = model.subtotal;
    if (subtotal <= 0 && model.items.isNotEmpty) {
      subtotal = model.items.fold(
        0.0,
        (sum, i) => sum + (i.lineTotal ?? (i.unitPrice ?? 0) * i.quantity),
      );
    }
    return InvoicePrintData(
      invoiceNumber: model.id.length > 8 ? model.id.substring(0, 8) : model.id,
      invoiceDate: model.createdAt ?? DateTime.now().toIso8601String().split('T').first,
      items: model.items,
      subtotal: subtotal,
      total: model.total,
      discount: model.discount,
      paymentMethod: model.paymentType,
      customerName: model.customerName,
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
    );
    await _printerService.printRaw(bytes);
  }

  Future<void> printInvoiceModel(InvoiceModel model) =>
      printInvoice(InvoicePrintData.fromModel(model));
}
