import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';

import '../../../data/models/invoice_model.dart';
import '../../../data/models/invoice_receipt_model.dart';
import '../models/customer_week_statement.dart';
import '../models/daily_sales_report.dart';
import '../models/printer_settings.dart';
import 'esc_pos_text_helper.dart';

class EscPosReceiptBuilder {
  int _paperWidthPx(int paperWidthMm) =>
      paperWidthMm == 80 ? PaperSize.mm80.width : PaperSize.mm58.width;

  double _lineTotal({
    required num quantity,
    double? unitPrice,
    double? lineTotal,
  }) {
    if (lineTotal != null) return lineTotal;
    return (unitPrice ?? 0) * quantity;
  }

  String _formatQty(num quantity) {
    final d = quantity.toDouble();
    if (d == d.roundToDouble()) {
      return d.toInt().toString();
    }
    final rounded = (d * 10000).roundToDouble() / 10000;
    return rounded
        .toStringAsFixed(4)
        .replaceAll(RegExp(r'0+$'), '')
        .replaceAll(RegExp(r'\.$'), '');
  }

  String _paymentLabelAr(String? paymentMethod) {
    final p = (paymentMethod ?? '').toLowerCase();
    if (p == 'cash') return 'نقدي';
    if (p == 'credit') return 'آجل';
    return EscPosTextHelper.sanitizeForEscPos(paymentMethod ?? '');
  }

  String _formatMoney(double value) => value.toStringAsFixed(2);

  String _formatMoneyAr(double value) => '${_formatMoney(value)} جنيه';

  String _formatInvoiceDate(String invoiceDate) {
    if (invoiceDate.length >= 10) {
      return invoiceDate.substring(0, 10);
    }
    return invoiceDate;
  }

  /// Four-column table header (الصنف | العدد | السعر | الإجمالي).
  Future<void> _printItemsTableHeader(
    Generator generator,
    List<int> bytes,
    int widthPx,
  ) async {
    await EscPosTextHelper.printTableRow(
      generator,
      bytes,
      paperWidthPx: widthPx,
      item: 'الصنف',
      qty: 'العدد',
      price: 'السعر',
      total: 'الإجمالي',
      bold: true,
    );
    bytes.addAll(generator.hr(ch: '-'));
  }

  /// One table row per line item — matches client receipt layout.
  Future<void> _printLineItem(
    Generator generator,
    List<int> bytes,
    int widthPx, {
    required String name,
    required num quantity,
    required double unitPrice,
    required double lineTotal,
  }) async {
    await EscPosTextHelper.printTableRow(
      generator,
      bytes,
      paperWidthPx: widthPx,
      item: name,
      qty: _formatQty(quantity),
      price: _formatMoney(unitPrice),
      total: _formatMoney(lineTotal),
    );
  }

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
    String? branchName,
    double? amountPaid,
    double? changeDue,
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

    await EscPosTextHelper.printLine(
      generator,
      bytes,
      'فاتورة رقم $invoiceNumber',
      styles: const PosStyles(align: PosAlign.center, bold: true),
      paperWidthPx: widthPx,
    );
    await EscPosTextHelper.printLine(
      generator,
      bytes,
      'التاريخ: ${_formatInvoiceDate(invoiceDate)}',
      paperWidthPx: widthPx,
    );
    if (branchName != null && branchName.trim().isNotEmpty) {
      await EscPosTextHelper.printLine(
        generator,
        bytes,
        'الفرع: ${branchName.trim()}',
        paperWidthPx: widthPx,
      );
    }
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
    await _printItemsTableHeader(generator, bytes, widthPx);

    for (final item in items) {
      final name = item.partName ?? item.partCode ?? item.partId;
      final unitPrice = item.unitPrice ?? 0;
      final lineTotal = _lineTotal(
        quantity: item.quantity,
        unitPrice: unitPrice,
        lineTotal: item.lineTotal,
      );
      await _printLineItem(
        generator,
        bytes,
        widthPx,
        name: name,
        quantity: item.quantity,
        unitPrice: unitPrice,
        lineTotal: lineTotal,
      );
    }

    bytes.addAll(generator.hr());
    await EscPosTextHelper.printLabelValueRow(
      generator,
      bytes,
      label: 'الإجمالي:',
      value: _formatMoneyAr(subtotal),
      paperWidthPx: widthPx,
    );
    if (discount > 0) {
      await EscPosTextHelper.printLabelValueRow(
        generator,
        bytes,
        label: 'الخصم:',
        value: '-${_formatMoney(discount)} جنيه',
        paperWidthPx: widthPx,
      );
    }
    await EscPosTextHelper.printLabelValueRow(
      generator,
      bytes,
      label: 'الصافي:',
      value: _formatMoneyAr(total),
      paperWidthPx: widthPx,
      bold: true,
    );
    if (paymentMethod != null && paymentMethod.isNotEmpty) {
      await EscPosTextHelper.printLabelValueRow(
        generator,
        bytes,
        label: 'طريقة الدفع:',
        value: _paymentLabelAr(paymentMethod),
        paperWidthPx: widthPx,
      );
    }
    final isCash = (paymentMethod ?? '').toLowerCase() == 'cash';
    if (isCash && amountPaid != null && amountPaid > 0) {
      await EscPosTextHelper.printLabelValueRow(
        generator,
        bytes,
        label: 'المدفوع:',
        value: _formatMoneyAr(amountPaid),
        paperWidthPx: widthPx,
      );
      final change =
          changeDue ?? (amountPaid > total ? amountPaid - total : 0);
      if (change > 0) {
        await EscPosTextHelper.printLabelValueRow(
          generator,
          bytes,
          label: 'الباقي:',
          value: _formatMoneyAr(change),
          paperWidthPx: widthPx,
          bold: true,
        );
      }
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

  /// Post-return statement: sold / returned / remaining per line + net totals.
  Future<List<int>> buildInvoiceReceiptStatement({
    required PrinterSettings settings,
    required InvoiceReceiptModel receipt,
  }) async {
    final profile = await CapabilityProfile.load();
    final paper = settings.paperWidthMm == 80 ? PaperSize.mm80 : PaperSize.mm58;
    final generator = Generator(paper, profile);
    final bytes = <int>[];
    final widthPx = _paperWidthPx(settings.paperWidthMm);
    final inv = receipt.invoice;
    final summary = receipt.summary;
    final invoiceNumber = inv.invoiceNumber ?? '—';
    final date = (inv.createdAt?.length ?? 0) >= 10
        ? inv.createdAt!.substring(0, 10)
        : (inv.createdAt ?? '');

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
      'Invoice $invoiceNumber',
      styles: const PosStyles(align: PosAlign.center, bold: true),
      paperWidthPx: widthPx,
    );
    if (date.isNotEmpty) {
      await EscPosTextHelper.printLine(
        generator,
        bytes,
        'Date: $date',
        paperWidthPx: widthPx,
      );
    }
    if (inv.branchName != null && inv.branchName!.isNotEmpty) {
      await EscPosTextHelper.printLine(
        generator,
        bytes,
        'Branch: ${inv.branchName!.trim()}',
        paperWidthPx: widthPx,
      );
    }
    if (inv.customerName != null && inv.customerName!.isNotEmpty) {
      await EscPosTextHelper.printLine(
        generator,
        bytes,
        'العميل: ${inv.customerName!.trim()}',
        styles: const PosStyles(align: PosAlign.center, bold: true),
        paperWidthPx: widthPx,
      );
    }
    bytes.addAll(generator.hr(ch: '-'));
    await EscPosTextHelper.printLine(
      generator,
      bytes,
      'الأصناف (مباع / مرتجع / متبقي)',
      styles: const PosStyles(align: PosAlign.center, bold: true),
      paperWidthPx: widthPx,
    );
    await _printItemsTableHeader(generator, bytes, widthPx);

    for (final line in receipt.items) {
      final name = line.partName ?? line.partCode ?? line.partId;
      final unitPrice = line.unitPrice ?? 0;
      final qty = line.quantityRemaining > 0
          ? line.quantityRemaining
          : line.quantity;
      final lineTotal = _lineTotal(
        quantity: qty,
        unitPrice: unitPrice,
        lineTotal: line.lineTotal,
      );
      await _printLineItem(
        generator,
        bytes,
        widthPx,
        name: name,
        quantity: qty,
        unitPrice: unitPrice,
        lineTotal: lineTotal,
      );
      if (line.quantityReturnedCompleted > 0 ||
          line.quantityReturnedPending > 0) {
        final retNote =
            'مباع ${line.quantity} · مرتجع ${line.quantityReturnedCompleted} · متبقي ${line.quantityRemaining}';
        await EscPosTextHelper.printLine(
          generator,
          bytes,
          retNote,
          styles: const PosStyles(align: PosAlign.right),
          paperWidthPx: widthPx,
        );
      }
    }

    bytes.addAll(generator.hr());
    final originalTotal = summary.originalTotal ?? inv.total ?? 0;
    final returned = summary.returnedValueCompleted ?? 0;
    final net = summary.netTotalAfterCompletedReturns ??
        (originalTotal - returned);

    EscPosTextHelper.printRow(generator, bytes, [
      PosColumn(text: 'Original:', width: 6),
      PosColumn(
        text: originalTotal.toStringAsFixed(2),
        width: 6,
        styles: const PosStyles(align: PosAlign.right),
      ),
    ]);
    EscPosTextHelper.printRow(generator, bytes, [
      PosColumn(text: 'Returned:', width: 6),
      PosColumn(
        text: returned.toStringAsFixed(2),
        width: 6,
        styles: const PosStyles(align: PosAlign.right),
      ),
    ]);
    EscPosTextHelper.printRow(generator, bytes, [
      PosColumn(text: 'NET:', width: 6, styles: const PosStyles(bold: true)),
      PosColumn(
        text: '${net.toStringAsFixed(2)} EGP',
        width: 6,
        styles: const PosStyles(align: PosAlign.right, bold: true),
      ),
    ]);

    if (receipt.returns.isNotEmpty) {
      bytes.addAll(generator.hr(ch: '-'));
      await EscPosTextHelper.printLine(
        generator,
        bytes,
        'Returns on invoice:',
        styles: const PosStyles(bold: true),
        paperWidthPx: widthPx,
      );
      for (final ret in receipt.returns) {
        final num = ret.returnNumber ?? '-';
        final amt = (ret.totalValue ?? 0).toStringAsFixed(2);
        final res = ret.resolution ?? ret.status ?? '';
        await EscPosTextHelper.printLine(
          generator,
          bytes,
          '$num: $amt ($res)',
          paperWidthPx: widthPx,
        );
      }
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

  Future<List<int>> buildDailySalesReport({
    required PrinterSettings settings,
    required DailySalesReport report,
    bool compact = false,
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
      styles: const PosStyles(align: PosAlign.center, bold: true),
      paperWidthPx: widthPx,
    );
    bytes.addAll(generator.hr());
    await EscPosTextHelper.printLine(
      generator,
      bytes,
      'تقرير مبيعات اليوم',
      styles: const PosStyles(align: PosAlign.center, bold: true),
      paperWidthPx: widthPx,
    );
    await EscPosTextHelper.printLine(
      generator,
      bytes,
      'Date: ${report.date}',
      paperWidthPx: widthPx,
    );
    if (report.branchName != null && report.branchName!.trim().isNotEmpty) {
      await EscPosTextHelper.printLine(
        generator,
        bytes,
        'Branch: ${report.branchName!.trim()}',
        paperWidthPx: widthPx,
      );
    }
    bytes.addAll(generator.hr(ch: '-'));

    if (report.lines.isEmpty && report.cashTotal <= 0) {
      await EscPosTextHelper.printLine(
        generator,
        bytes,
        'No sales today',
        styles: const PosStyles(align: PosAlign.center),
        paperWidthPx: widthPx,
      );
    } else if (compact) {
      EscPosTextHelper.printRow(generator, bytes, [
        PosColumn(text: 'Invoices:', width: 6),
        PosColumn(
          text: '${report.invoiceCount}',
          width: 6,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]);
      EscPosTextHelper.printRow(generator, bytes, [
        PosColumn(text: 'Cash total:', width: 6, styles: const PosStyles(bold: true)),
        PosColumn(
          text: '${_formatMoney(report.cashTotal)} EGP',
          width: 6,
          styles: const PosStyles(align: PosAlign.right, bold: true),
        ),
      ]);
      if (report.discountTotal > 0) {
        EscPosTextHelper.printRow(generator, bytes, [
          PosColumn(text: 'Discount:', width: 6),
          PosColumn(
            text: '-${_formatMoney(report.discountTotal)}',
            width: 6,
            styles: const PosStyles(align: PosAlign.right),
          ),
        ]);
      }
    } else {
      await EscPosTextHelper.printTableRow(
        generator,
        bytes,
        paperWidthPx: widthPx,
        item: 'فاتورة',
        qty: 'نوع',
        price: 'العميل',
        total: 'الإجمالي',
        bold: true,
      );
      bytes.addAll(generator.hr(ch: '-'));

      for (final line in report.lines) {
        final payment = line.isCash ? 'نقدي' : 'آجل';
        final number = line.pending ? '${line.invoiceNumber}*' : line.invoiceNumber;
        await EscPosTextHelper.printTableRow(
          generator,
          bytes,
          paperWidthPx: widthPx,
          item: number,
          qty: payment,
          price: line.customerName,
          total: _formatMoney(line.total),
        );
        if (line.time.isNotEmpty) {
          await EscPosTextHelper.printLine(
            generator,
            bytes,
            line.time,
            styles: const PosStyles(align: PosAlign.right),
            paperWidthPx: widthPx,
          );
        }
      }
    }

    if (!compact) {
      bytes.addAll(generator.hr());
      EscPosTextHelper.printRow(generator, bytes, [
        PosColumn(text: 'Invoices:', width: 6),
        PosColumn(
          text: '${report.invoiceCount}',
          width: 6,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]);
      EscPosTextHelper.printRow(generator, bytes, [
        PosColumn(text: 'Cash:', width: 6),
        PosColumn(
          text: _formatMoney(report.cashTotal),
          width: 6,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]);
      EscPosTextHelper.printRow(generator, bytes, [
        PosColumn(text: 'Credit:', width: 6),
        PosColumn(
          text: _formatMoney(report.creditTotal),
          width: 6,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]);
      if (report.discountTotal > 0) {
        EscPosTextHelper.printRow(generator, bytes, [
          PosColumn(text: 'Discount:', width: 6),
          PosColumn(
            text: '-${_formatMoney(report.discountTotal)}',
            width: 6,
            styles: const PosStyles(align: PosAlign.right),
          ),
        ]);
      }
      EscPosTextHelper.printRow(generator, bytes, [
        PosColumn(text: 'TOTAL:', width: 6, styles: const PosStyles(bold: true)),
        PosColumn(
          text: '${_formatMoney(report.grandTotal)} EGP',
          width: 6,
          styles: const PosStyles(align: PosAlign.right, bold: true),
        ),
      ]);
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

  /// Daily drawer: cash sales + collections − outflows = drawer total.
  Future<List<int>> buildDailyDrawerReport({
    required PrinterSettings settings,
    required DailySalesReport report,
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
      styles: const PosStyles(align: PosAlign.center, bold: true),
      paperWidthPx: widthPx,
    );
    bytes.addAll(generator.hr());
    await EscPosTextHelper.printLine(
      generator,
      bytes,
      'تقرير الدرج اليومي',
      styles: const PosStyles(align: PosAlign.center, bold: true),
      paperWidthPx: widthPx,
    );
    await EscPosTextHelper.printLine(
      generator,
      bytes,
      'التاريخ: ${report.date}',
      paperWidthPx: widthPx,
    );
    if (report.branchName != null && report.branchName!.trim().isNotEmpty) {
      await EscPosTextHelper.printLine(
        generator,
        bytes,
        'الفرع: ${report.branchName!.trim()}',
        paperWidthPx: widthPx,
      );
    }
    bytes.addAll(generator.hr(ch: '-'));

    await EscPosTextHelper.printLine(
      generator,
      bytes,
      'المبيعات النقدية',
      styles: const PosStyles(bold: true),
      paperWidthPx: widthPx,
    );
    await EscPosTextHelper.printLabelValueRow(
      generator,
      bytes,
      label: 'الإجمالي:',
      value: _formatMoneyAr(report.cashSalesTotal),
      paperWidthPx: widthPx,
    );

    bytes.addAll(generator.hr(ch: '-'));
    await EscPosTextHelper.printLine(
      generator,
      bytes,
      'تحصيلات العملاء',
      styles: const PosStyles(bold: true),
      paperWidthPx: widthPx,
    );
    if (report.collections.isEmpty) {
      await EscPosTextHelper.printLine(
        generator,
        bytes,
        report.collectionsDetailUnavailable
            ? 'تفاصيل التحصيلات متاحة عند توفر API'
            : '—',
        paperWidthPx: widthPx,
      );
    } else {
      for (final line in report.collections) {
        await EscPosTextHelper.printColumns(
          generator,
          bytes,
          left: line.label,
          right: _formatMoneyAr(line.amount),
          paperWidthPx: widthPx,
        );
      }
    }

    final cashInSubtotal = report.cashInTotal > 0
        ? report.cashInTotal
        : report.cashSalesTotal + report.collectionsTotal;
    bytes.addAll(generator.hr());
    await EscPosTextHelper.printLabelValueRow(
      generator,
      bytes,
      label: 'الإجمالي:',
      value: _formatMoneyAr(cashInSubtotal),
      paperWidthPx: widthPx,
      bold: true,
    );

    bytes.addAll(generator.hr(ch: '-'));
    await EscPosTextHelper.printLine(
      generator,
      bytes,
      '(−) مدفوعات الموردين والمصاريف النقدية',
      styles: const PosStyles(bold: true),
      paperWidthPx: widthPx,
    );
    if (report.outflows.isEmpty) {
      await EscPosTextHelper.printLabelValueRow(
        generator,
        bytes,
        label: 'الإجمالي:',
        value: _formatMoneyAr(report.cashOutTotal),
        paperWidthPx: widthPx,
      );
    } else {
      for (final line in report.outflows) {
        await EscPosTextHelper.printColumns(
          generator,
          bytes,
          left: line.label,
          right: _formatMoneyAr(line.amount),
          paperWidthPx: widthPx,
        );
      }
    }

    final drawer = report.drawerTotal != 0
        ? report.drawerTotal
        : report.computedDrawerTotal;
    bytes.addAll(generator.hr());
    await EscPosTextHelper.printLabelValueRow(
      generator,
      bytes,
      label: 'الإجمالي في الدرج:',
      value: _formatMoneyAr(drawer),
      paperWidthPx: widthPx,
      bold: true,
    );

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

  Future<List<int>> buildCustomerWeeklyStatement({
    required PrinterSettings settings,
    required CustomerWeekStatement statement,
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
      styles: const PosStyles(align: PosAlign.center, bold: true),
      paperWidthPx: widthPx,
    );
    bytes.addAll(generator.hr());
    await EscPosTextHelper.printLine(
      generator,
      bytes,
      'كشف حساب أسبوعي',
      styles: const PosStyles(align: PosAlign.center, bold: true),
      paperWidthPx: widthPx,
    );
    await EscPosTextHelper.printLine(
      generator,
      bytes,
      'العميل: ${statement.customerName}',
      styles: const PosStyles(align: PosAlign.center, bold: true),
      paperWidthPx: widthPx,
    );
    if (statement.customerPhone != null &&
        statement.customerPhone!.trim().isNotEmpty) {
      await EscPosTextHelper.printLine(
        generator,
        bytes,
        'الهاتف: ${statement.customerPhone!.trim()}',
        paperWidthPx: widthPx,
      );
    }
    await EscPosTextHelper.printLine(
      generator,
      bytes,
      'من ${statement.weekStart} إلى ${statement.weekEnd}',
      paperWidthPx: widthPx,
    );
    bytes.addAll(generator.hr(ch: '-'));
    await _printItemsTableHeader(generator, bytes, widthPx);

    for (final line in statement.lines) {
      await _printLineItem(
        generator,
        bytes,
        widthPx,
        name: line.partName,
        quantity: line.quantity,
        unitPrice: line.unitPrice,
        lineTotal: line.lineTotal,
      );
    }

    bytes.addAll(generator.hr());
    await EscPosTextHelper.printLabelValueRow(
      generator,
      bytes,
      label: 'إجمالي الأسبوع:',
      value: _formatMoneyAr(statement.weekTotal),
      paperWidthPx: widthPx,
      bold: true,
    );
    final payments = statement.paymentsCollected;
    if (payments != null && payments > 0) {
      await EscPosTextHelper.printLabelValueRow(
        generator,
        bytes,
        label: 'المدفوع هذا الأسبوع:',
        value: _formatMoneyAr(payments),
        paperWidthPx: widthPx,
      );
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
