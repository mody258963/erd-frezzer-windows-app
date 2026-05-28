import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';

import '../../../data/models/invoice_model.dart';
import '../models/printer_settings.dart';
import 'esc_pos_text_helper.dart';

class EscPosReceiptBuilder {
  int _paperWidthPx(int paperWidthMm) =>
      paperWidthMm == 80 ? PaperSize.mm80.width : PaperSize.mm58.width;

  Future<List<int>> buildTestPage(PrinterSettings settings) async {
    final profile = await CapabilityProfile.load();
    final paper = settings.paperWidthMm == 80 ? PaperSize.mm80 : PaperSize.mm58;
    final generator = Generator(paper, profile);
    final bytes = <int>[];
    final widthPx = _paperWidthPx(settings.paperWidthMm);

    bytes.addAll(generator.reset());
    await EscPosTextHelper.printLine(
      generator,
      bytes,
      settings.companyName,
      styles: const PosStyles(align: PosAlign.center, bold: true),
      paperWidthPx: widthPx,
    );
    bytes.addAll(generator.hr());
    await EscPosTextHelper.printLine(
      generator,
      bytes,
      'TEST PAGE',
      styles: const PosStyles(align: PosAlign.center),
      paperWidthPx: widthPx,
    );
    await EscPosTextHelper.printLine(
      generator,
      bytes,
      'اختبار الطابعة',
      styles: const PosStyles(align: PosAlign.center),
      paperWidthPx: widthPx,
    );
    bytes.addAll(generator.hr());
    await EscPosTextHelper.printLine(
      generator,
      bytes,
      settings.receiptFooter,
      styles: const PosStyles(align: PosAlign.center),
      paperWidthPx: widthPx,
    );
    bytes.addAll(generator.feed(2));
    bytes.addAll(generator.cut());
    return bytes;
  }

  Future<List<int>> buildInvoice({
    required PrinterSettings settings,
    required String invoiceNumber,
    required String invoiceDate,
    required List<InvoiceItemModel> items,
    required double subtotal,
    required double total,
    double discount = 0,
    String? paymentMethod,
    String? customerName,
  }) async {
    final profile = await CapabilityProfile.load();
    final paper = settings.paperWidthMm == 80 ? PaperSize.mm80 : PaperSize.mm58;
    final generator = Generator(paper, profile);
    final bytes = <int>[];
    final widthPx = _paperWidthPx(settings.paperWidthMm);

    bytes.addAll(generator.reset());
    await EscPosTextHelper.printLine(
      generator,
      bytes,
      settings.companyName,
      styles: const PosStyles(
        align: PosAlign.center,
        bold: true,
        height: PosTextSize.size2,
      ),
      paperWidthPx: widthPx,
    );
    bytes.addAll(generator.hr());

    bytes.addAll(generator.row([
      PosColumn(text: 'Invoice #:', width: 6),
      PosColumn(text: invoiceNumber, width: 6),
    ]));
    bytes.addAll(generator.row([
      PosColumn(text: 'Date:', width: 6),
      PosColumn(text: invoiceDate, width: 6),
    ]));
    if (customerName != null && customerName.trim().isNotEmpty) {
      await EscPosTextHelper.printLine(
        generator,
        bytes,
        'العميل: ${customerName.trim()}',
        styles: const PosStyles(align: PosAlign.center, bold: true),
        paperWidthPx: widthPx,
      );
    }
    bytes.addAll(generator.hr(ch: '-'));
    bytes.addAll(generator.text('Items:', styles: const PosStyles(bold: true)));

    for (final item in items) {
      final name = item.partName ?? item.partCode ?? item.partId;
      final shortName =
          name.length > 20 ? '${name.substring(0, 20)}…' : name;
      final line = '$shortName x${item.quantity}';
      final price =
          (item.lineTotal ?? item.unitPrice ?? 0).toStringAsFixed(2);
      await EscPosTextHelper.printColumns(
        generator,
        bytes,
        left: line,
        right: price,
        paperWidthPx: widthPx,
      );
    }

    bytes.addAll(generator.hr());
    bytes.addAll(generator.row([
      PosColumn(text: 'Subtotal:', width: 6),
      PosColumn(
        text: subtotal.toStringAsFixed(2),
        width: 6,
        styles: const PosStyles(align: PosAlign.right),
      ),
    ]));
    if (discount > 0) {
      bytes.addAll(generator.row([
        PosColumn(text: 'Discount:', width: 6),
        PosColumn(
          text: '-${discount.toStringAsFixed(2)}',
          width: 6,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]));
    }
    bytes.addAll(generator.row([
      PosColumn(text: 'TOTAL:', width: 6, styles: const PosStyles(bold: true)),
      PosColumn(
        text: '${total.toStringAsFixed(2)} EGP',
        width: 6,
        styles: const PosStyles(align: PosAlign.right, bold: true),
      ),
    ]));
    if (paymentMethod != null && paymentMethod.isNotEmpty) {
      bytes.addAll(generator.text('Payment: $paymentMethod'));
    }
    bytes.addAll(generator.hr());
    await EscPosTextHelper.printLine(
      generator,
      bytes,
      settings.receiptPhone,
      styles: const PosStyles(align: PosAlign.center),
      paperWidthPx: widthPx,
    );
    await EscPosTextHelper.printLine(
      generator,
      bytes,
      settings.receiptFooter,
      styles: const PosStyles(align: PosAlign.center),
      paperWidthPx: widthPx,
    );
    bytes.addAll(generator.feed(2));
    bytes.addAll(generator.cut());
    return bytes;
  }
}
