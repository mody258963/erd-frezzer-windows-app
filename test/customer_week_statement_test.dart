import 'package:erd_rezzer/core/printer/models/daily_sales_report.dart';
import 'package:erd_rezzer/data/models/invoice_model.dart';
import 'package:erd_rezzer/features/customers/customer_week_statement.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('aggregateWeekPurchaseLines', () {
    test('groups same part across invoices', () {
      final invoices = [
        InvoiceModel(
          id: '1',
          branchId: 'b1',
          customerId: 'c1',
          paymentType: 'credit',
          total: 150,
          items: [
            InvoiceItemModel(
              partId: 'p1',
              partName: 'Tomato',
              quantity: 2,
              unitPrice: 25,
              lineTotal: 50,
            ),
            InvoiceItemModel(
              partId: 'p2',
              partName: 'Onion',
              quantity: 1,
              unitPrice: 30,
              lineTotal: 30,
            ),
          ],
        ),
        InvoiceModel(
          id: '2',
          branchId: 'b1',
          customerId: 'c1',
          paymentType: 'credit',
          total: 100,
          items: [
            InvoiceItemModel(
              partId: 'p1',
              partName: 'Tomato',
              quantity: 3,
              unitPrice: 25,
              lineTotal: 75,
            ),
          ],
        ),
      ];

      final lines = aggregateWeekPurchaseLines(invoices);
      expect(lines, hasLength(2));

      final tomato = lines.firstWhere((l) => l.partId == 'p1');
      expect(tomato.quantity, 5);
      expect(tomato.lineTotal, 125);
      expect(tomato.unitPrice, 25);
    });
  });

  group('buildCustomerWeekStatement', () {
    test('computes week total from aggregated lines', () {
      final statement = buildCustomerWeekStatement(
        customerName: 'Ahmed',
        weekInvoices: [
          InvoiceModel(
            id: '1',
            branchId: 'b1',
            customerId: 'c1',
            paymentType: 'credit',
            total: 40,
            items: [
              InvoiceItemModel(
                partId: 'p1',
                partName: 'Item',
                quantity: 2,
                unitPrice: 20,
                lineTotal: 40,
              ),
            ],
          ),
        ],
      );

      expect(statement.customerName, 'Ahmed');
      expect(statement.weekTotal, 40);
      expect(statement.lines, hasLength(1));
    });
  });

  group('DailySalesReport drawer totals', () {
    test('computedDrawerTotal matches cash in minus outflows', () {
      const report = DailySalesReport(
        date: '2026-06-16',
        lines: [],
        invoiceCount: 0,
        cashTotal: 500,
        creditTotal: 0,
        discountTotal: 0,
        grandTotal: 500,
        cashSalesTotal: 500,
        collections: [
          DailyDrawerLine(label: 'Customer A', amount: 200),
        ],
        outflows: [
          DailyDrawerLine(label: 'Supplier', amount: 150),
        ],
      );

      expect(report.collectionsTotal, 200);
      expect(report.outflowsTotal, 150);
      expect(report.computedDrawerTotal, 550);
    });
  });
}
