import '../../data/models/invoice_model.dart';
import '../../data/repositories/invoice_repository.dart';
import '../../di/injection.dart';
import 'services/invoice_printer_service.dart';
import 'services/printer_manager.dart';
import 'services/printer_service.dart';
import 'models/daily_sales_report.dart';

/// Ensures default printer is connected, then prints.
Future<void> printWithConnectedPrinter(
  Future<void> Function() printAction,
) async {
  final manager = getIt<PrinterManager>();
  final service = getIt<PrinterService>();
  if (service.connectedPrinter == null) {
    final settings = manager.settings;
    if (settings.selectedPrinterId == null) {
      throw PrinterException('Configure a printer in Settings first');
    }
    await manager.reconnectIfConfigured();
    if (service.connectedPrinter == null) {
      throw PrinterException('Could not connect to printer. Open Printer settings and tap Connect.');
    }
  }
  await printAction();
}

Future<void> printInvoiceData(InvoicePrintData data) async {
  await printWithConnectedPrinter(
    () => getIt<InvoicePrinterService>().printInvoice(data),
  );
}

Future<void> printInvoiceReceiptById(String invoiceId) async {
  final receipt = await getIt<InvoiceRepository>().receipt(invoiceId);
  await printWithConnectedPrinter(
    () => getIt<InvoicePrinterService>().printReceiptStatement(receipt),
  );
}

Future<void> printInvoicesBatch(List<InvoiceModel> invoices) async {
  if (invoices.isEmpty) return;
  await printWithConnectedPrinter(
    () => getIt<InvoicePrinterService>().printInvoiceModelsBatch(invoices),
  );
}

Future<void> printDailySalesReport(DailySalesReport report) async {
  await printWithConnectedPrinter(
    () => getIt<InvoicePrinterService>().printDailySalesReport(report),
  );
}
